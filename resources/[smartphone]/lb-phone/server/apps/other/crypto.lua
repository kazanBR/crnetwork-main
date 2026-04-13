-- ── Guard: abort early if crypto is disabled in config ───────
if not (Config.Crypto and Config.Crypto.Enabled) then
  debugprint("crypto disabled")
  return
end

-- ── Transaction limits (fallback to 1,000,000 if not set) ────
local limits = (Config.Crypto and Config.Crypto.Limits) or { Buy = 1000000, Sell = 1000000 }

-- ── Module-level state ────────────────────────────────────────
local coins         = {}    -- live coin data keyed by coin id
local priceHistory  = {}    -- full timestamped history keyed by coin id
local isReady       = false -- true once the price loop has initialised
local openPlayers   = {}    -- server IDs that currently have the crypto app open
local refundedIds   = {}    -- set of identifiers already refunded this run

-- Snapshot of coin prices from the previous server run (for refund/convert logic)
local previousCoinData = (function()
  local raw = GetResourceKvpString("lb-phone:crypto:coins")
  return raw and json.decode(raw) or {}
end)()

-- ─────────────────────────────────────────────────────────────
-- broadcastToOpenPlayers  (internal helper)
-- Sends a latent client event to every player who has the
-- crypto app open, packing args with msgpack for efficiency.
-- ─────────────────────────────────────────────────────────────
local function broadcastToOpenPlayers(eventName, ...)
  if #openPlayers == 0 then return end
  local packed     = msgpack.pack_args(...)
  local packedSize = #packed
  for _, playerId in ipairs(openPlayers) do
    TriggerLatentClientEventInternal(eventName, playerId, packed, packedSize, 1000000.0)
  end
end

-- ─────────────────────────────────────────────────────────────
-- weightedRandom  (internal helper)
-- Picks an index from a weights table using weighted random
-- selection. Falls back to index 1.
-- ─────────────────────────────────────────────────────────────
local function weightedRandom(weights)
  local total = 0
  for _, w in ipairs(weights) do total = total + w end
  local roll = math.random() * total
  for i, w in ipairs(weights) do
    roll = roll - w
    if roll <= 0 then return i end
  end
  return 1
end

-- ─────────────────────────────────────────────────────────────
-- insertOrUpdateCoin  (internal helper)
-- Upserts a player's crypto holding in the database.
-- ─────────────────────────────────────────────────────────────
local function insertOrUpdateCoin(identifier, coinId, amount, invested)
  MySQL.update.await(
    "INSERT INTO phone_crypto (id, coin, amount, invested) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE amount = amount + VALUES(amount), invested = invested + VALUES(invested)",
    { identifier, coinId, amount, invested or 0 }
  )
end

-- ─────────────────────────────────────────────────────────────
-- resolveIdentifier  (internal helper)
-- Accepts either a server source (number) or a raw identifier
-- string and always returns the identifier string.
-- ─────────────────────────────────────────────────────────────
local function resolveIdentifier(sourceOrIdentifier)
  if type(sourceOrIdentifier) == "number" then
    return GetIdentifier(sourceOrIdentifier)
  end
  return sourceOrIdentifier
end

-- ─────────────────────────────────────────────────────────────
-- phone:crypto:setAppOpen  (net event)
-- Tracks which players have the crypto app open so targeted
-- latent price updates can be sent only to them.
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("phone:crypto:setAppOpen", function(isOpen)
  local playerId     = source
  local found, index = table.contains(openPlayers, playerId)
  if found and not isOpen then
    table.remove(openPlayers, index)
  elseif not found and isOpen then
    openPlayers[#openPlayers + 1] = playerId
  end
end)

-- ─────────────────────────────────────────────────────────────
-- playerDropped  (event)
-- Removes disconnecting players from the open-app list.
-- ─────────────────────────────────────────────────────────────
AddEventHandler("playerDropped", function()
  local found, index = table.contains(openPlayers, source)
  if found then table.remove(openPlayers, index) end
end)

-- ─────────────────────────────────────────────────────────────
-- refundPlayerCoins  (internal helper)
-- Called once per identifier when they first log in after a
-- coin has been removed from the config. Calculates refund
-- value per Config.Crypto.Refund ("invested"|"lastValue"|"convert"),
-- pays it out, then deletes the orphaned DB rows.
-- ─────────────────────────────────────────────────────────────
local function refundPlayerCoins(playerSource, identifier, ownedRows)
  -- Guard: only process once per server run per identifier
  if GetResourceKvpInt("crypto:refund:" .. identifier) == 1 then
    debugprint("refund already processed for identifier", identifier)
    return
  end

  -- Collect rows whose coin no longer exists in config
  local orphaned = {}
  for _, row in ipairs(ownedRows) do
    if not coins[row.coin] and row.amount > 0 then
      orphaned[#orphaned + 1] = row
    end
  end

  local refundMethod = Config.Crypto.Refund
  local totalRefund  = 0

  if refundMethod == "invested" then
    for _, row in ipairs(orphaned) do
      totalRefund = totalRefund + row.invested
    end

  elseif refundMethod == "lastValue" then
    if not (previousCoinData and next(previousCoinData)) then
      infoprint("warning", "Config.Crypto.Refund is set to 'lastValue', but no old coin data was found")
    end
    for _, row in ipairs(orphaned) do
      local oldCoin = previousCoinData[row.coin]
      if not oldCoin then
        infoprint("warning", "no old coin data found for coin", row.coin, "- cannot refund last value. Consider changing refund method to 'invested'")
        return
      end
      totalRefund = totalRefund + (row.amount * oldCoin.current_price)
    end

  elseif refundMethod == "convert" then
    if not (Config.Crypto.Coins and Config.Crypto.Coins.lbc) then
      infoprint("warning", "Config.Crypto.Refund is set to 'convert', but LB Coin is not configured as a crypto coin")
      return
    end
    local lbcData = coins.lbc
    if not lbcData then
      infoprint("warning", "LB Coin data not found - cannot convert old crypto to lbc")
      return
    end

    local totalValue = 0
    for _, row in ipairs(orphaned) do
      local oldCoin = previousCoinData[row.coin]
      if not oldCoin then
        infoprint("warning", "no old coin data found for coin", row.coin, "- cannot convert to lbc. Consider changing refund method to 'invested'")
        return
      end
      totalValue = totalValue + (row.amount * oldCoin.current_price)
    end

    local lbcAmount = totalValue / lbcData.current_price
    debugprint("Converting old crypto to LB Coin at rate", lbcData.current_price, "-> refund amount in LBC:", lbcAmount)
    insertOrUpdateCoin(identifier, "lbc", lbcAmount, totalValue)

    -- Notify the player in-game if they are online
    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    local onlineSource = phoneNumber and GetSourceFromNumber(phoneNumber)
    if onlineSource then
      SendNotification(onlineSource, {
        app     = "Crypto",
        title   = L("APPS.CRYPTO.CONVERT_NOTIFICATION.TITLE"),
        content = L("APPS.CRYPTO.CONVERT_NOTIFICATION.DESCRIPTION", {
          amount   = math.round(lbcAmount, 3),
          coinName = lbcData.name,
        }),
      })
    end
  end

  -- Pay out cash refund if applicable
  if totalRefund > 0 then
    local rounded = math.floor(totalRefund + 0.5)
    debugprint("Refund", identifier, "with amount", rounded)
    AddMoney(playerSource, rounded)

    local phoneNumber = GetEquippedPhoneNumber(playerSource)
    if phoneNumber then
      AddTransaction(phoneNumber, rounded, L("APPS.CRYPTO.REFUND_TRANSACTION"), "./assets/img/icons/apps/Crypto.jpg")
    end
  end

  -- Build list of orphaned coin IDs and remove them from the DB
  local coinIds = {}
  for _, row in ipairs(orphaned) do
    coinIds[#coinIds + 1] = row.coin
  end
  if #coinIds > 0 then
    MySQL.update.await(
      "DELETE FROM phone_crypto WHERE id = ? AND coin IN (?)",
      { identifier, coinIds }
    )
  end

  -- Mark as refunded so this won't run again this session
  SetResourceKvpInt("crypto:refund:" .. identifier, 1)
end

-- ─────────────────────────────────────────────────────────────
-- Price update thread
-- Initialises coin data from config + DB, then loops forever
-- updating prices via weighted random change entries.
-- ─────────────────────────────────────────────────────────────
CreateThread(function()
  -- Nothing to do if Coins table is missing or empty
  if not (Config.Crypto.Coins and next(Config.Crypto.Coins)) then
    isReady = true
    return
  end

  -- Wait for the database checker before touching the DB
  while not DatabaseCheckerFinished do Wait(500) end

  -- Validate that Coins is a keyed object, not an array
  if table.type(Config.Crypto.Coins) == "array" then
    infoprint("error", "Config.Crypto.Coins is an array, but it should be an object.")
  end

  -- ── Load persisted timing state ───────────────────────────
  local lastUpdated      = GetResourceKvpInt("crypto:lastUpdated")      or 0
  local lastTrackedPrice = GetResourceKvpInt("crypto:lastTrackedPrice") or 0

  -- Calculate the update interval and how long until the next tick
  local intervalMs  = math.floor((Config.Crypto.UpdateInterval or 5) * 60 * 1000)
  local msUntilNext = intervalMs - ((os.time() * 1000) - (lastUpdated * 1000))
  -- Maximum history entries to keep (one per interval across a 24 h window)
  local maxHistory  = math.floor(86400 / math.max(900, math.floor(intervalMs / 1000)))

  -- ── Populate coins table from config ──────────────────────
  for coinId, coinCfg in pairs(Config.Crypto.Coins) do
    coins[coinId] = {
      id            = coinId,
      name          = coinCfg.name,
      symbol        = coinId,
      permissions   = coinCfg.permissions,
      change_24h    = 0,
      current_price = math.clamp(coinCfg.initialValue, 0.1, math.huge),
      image         = coinCfg.icon,
      prices        = {},
    }
  end

  -- ── Restore saved prices and 24 h history ─────────────────
  local savedPrices = MySQL.query.await("SELECT coin, coin_value FROM phone_crypto_coins")
  for _, row in ipairs(savedPrices) do
    local coin = coins[row.coin]
    if not coin then
      debugprint("Unknown coin in database:", row.coin)
    else
      coin.current_price = row.coin_value

      local historyJson = GetResourceKvpString("crypto:history:" .. row.coin)
      if historyJson then
        local history  = json.decode(historyJson)
        local cutoffTs = os.time() - 86400  -- discard entries older than 24 h

        -- Walk backwards so we can safely remove stale entries
        for i = #history, 1, -1 do
          if history[i].time >= cutoffTs then
            coin.prices[#coin.prices + 1] = history[i].value
          else
            table.remove(history, i)
          end
        end

        priceHistory[row.coin] = history

        -- Recalculate 24 h change from restored history
        if #history >= 2 then
          local oldest    = history[1].value
          local newest    = history[#history].value
          coin.change_24h = ((newest - oldest) / oldest) * 100
        end
      end
    end
  end

  isReady = true

  -- Optionally wait out the remaining time before the first update
  if msUntilNext > 0 and intervalMs > msUntilNext then
    debugprint("waiting " .. math.floor(msUntilNext / 1000) .. "s until next crypto update")
    Wait(msUntilNext)
  end

  -- Pre-build per-coin weight tables to avoid rebuilding every tick
  local changeWeights = {}
  for coinId, coinCfg in pairs(Config.Crypto.Coins) do
    local weights = {}
    for i, entry in ipairs(coinCfg.changes) do
      weights[i] = entry.weight
    end
    changeWeights[coinId] = weights
  end

  -- ── Main price update loop ─────────────────────────────────
  while true do
    local loopStart = os.nanotime()
    debugprint("Updating crypto coins")

    local newPriceRows = {}
    local now          = os.time()

    -- Advance lastTrackedPrice if the interval has elapsed
    if (now - lastTrackedPrice) >= (intervalMs / 1000) then
      lastTrackedPrice = now
      SetResourceKvpInt("crypto:lastTrackedPrice", lastTrackedPrice)
    end

    for coinId, coinCfg in pairs(Config.Crypto.Coins) do
      local coin        = coins[coinId]
      local changeEntry = coinCfg.changes[weightedRandom(changeWeights[coinId])]
      local changeRange = changeEntry and changeEntry.change or { 0, 0 }

      -- Apply a random percentage change within the selected range
      local changePct = changeRange[1] + math.random() * (changeRange[2] - changeRange[1])
      local oldPrice  = coin.current_price
      local newPrice  = oldPrice + oldPrice * (changePct / 100)

      -- Colour-coded console debug log
      local signColour = changePct > 0 and "^2+" or "^1"
      local pctColour  = changePct > 0 and "^2"  or "^1"
      local oldColour  = changePct > 0 and "^1"  or "^2"
      debugprint(string.format(
        "Coin ^4%s^7: %s%.2f%%^7 -> new price: %s%.2f^7, old price: %s%.2f^7",
        coinId, signColour, changePct, pctColour, newPrice, oldColour, oldPrice
      ))

      coin.current_price = newPrice

      -- Record history point when the tracking interval has just ticked
      if (now - lastTrackedPrice) <= 0 then
        priceHistory[coinId] = priceHistory[coinId] or {}
        local history = priceHistory[coinId]

        -- Trim both the display prices and full history to maxHistory
        while #coin.prices >= maxHistory do table.remove(coin.prices, 1) end
        while #history     >= maxHistory do table.remove(history,     1) end

        coin.prices[#coin.prices + 1] = newPrice
        history[#history + 1]         = { time = now, value = newPrice }

        SetResourceKvp("crypto:history:" .. coinId, json.encode(history))
      end

      -- Recalculate 24 h change from the current price window
      if #coin.prices > 0 then
        local oldest    = coin.prices[1]
        local newest    = coin.prices[#coin.prices]
        coin.change_24h = ((newest - oldest) / oldest) * 100
      end

      newPriceRows[#newPriceRows + 1] = { coinId, newPrice }
    end

    -- Persist updated prices to the DB
    MySQL.prepare.await(
      "INSERT INTO phone_crypto_coins (coin, coin_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE coin_value = VALUES(coin_value)",
      newPriceRows
    )
    SetResourceKvpInt("crypto:lastUpdated", os.time())

    -- Push updated coin data to all players with the app open
    broadcastToOpenPlayers("phone:crypto:updateCoins", coins)

    local elapsedMs = (os.nanotime() - loopStart) / 1000000.0
    debugprint(string.format("Updated crypto coins in %.4fms.", elapsedMs))

    Wait(intervalMs)
  end
end)

-- ─────────────────────────────────────────────────────────────
-- crypto:get  (callback)
-- Returns the full coin table with this player's owned amounts
-- merged in. Triggers a one-time orphan refund if needed.
-- ─────────────────────────────────────────────────────────────
RegisterCallback("crypto:get", function(source)
  local identifier = GetIdentifier(source)
  if not identifier then return {} end

  -- Wait until both the price loop and DB are ready
  while not (isReady and DatabaseCheckerFinished) do Wait(500) end

  local ownedRows = MySQL.query.await(
    "SELECT coin, amount, invested FROM phone_crypto WHERE id = ?",
    { identifier }
  )

  -- Deep-clone the live coin table so we can annotate it per-player
  local result = table.deep_clone(coins)
  for _, row in ipairs(ownedRows) do
    if row and result[row.coin] then
      result[row.coin].owned    = row.amount
      result[row.coin].invested = row.invested
    end
  end

  -- One-time refund for coins removed from config since last run
  if Config.Crypto.Refund and not refundedIds[identifier] then
    refundedIds[identifier] = true
    refundPlayerCoins(source, identifier, ownedRows)
  end

  return result
end, { preventSpam = true })

-- ─────────────────────────────────────────────────────────────
-- crypto:buy  (callback)
-- Validates and processes a coin purchase.
-- ─────────────────────────────────────────────────────────────
RegisterCallback("crypto:buy", function(source, coinId, amount)
  local identifier = GetIdentifier(source)
  local balance    = GetBalance(source)

  if amount <= 0 then
    return { success = false, msg = "INVALID_AMOUNT" }
  end
  if amount > limits.Buy then
    debugprint(amount, "is above crypto buy limit")
    return { success = false, msg = "INVALID_AMOUNT" }
  end
  if amount > balance then
    return { success = false, msg = "NO_MONEY" }
  end

  local coin = coins[coinId]
  if not coin then
    return { success = false, msg = "INVALID_COIN" }
  end

  if coin.permissions then
    if coin.permissions.buy == false then
      return { success = false, msg = "BUY_DISABLED" }
    end
  elseif not identifier then
    return { success = false, msg = "NO_IDENTIFIER" }
  else
    if not ValidateChecks("buyCrypto", source, coinId, amount) then
      return { success = false, msg = "CHECK_FAILED" }
    end
  end

  local coinAmount = amount / coin.current_price
  insertOrUpdateCoin(identifier, coinId, coinAmount, amount)
  RemoveMoney(source, amount)

  Log("Crypto", source, "success",
    L("BACKEND.LOGS.BOUGHT_CRYPTO"),
    L("BACKEND.LOGS.CRYPTO_DETAILS", { coin = coinId, amount = coinAmount, price = amount })
  )

  return { success = true }
end, { preventSpam = true })

-- ─────────────────────────────────────────────────────────────
-- crypto:sell  (callback)
-- Validates and processes a coin sale.
-- ─────────────────────────────────────────────────────────────
RegisterCallback("crypto:sell", function(source, coinId, amount)
  local identifier = GetIdentifier(source)

  if amount <= 0 then
    return { success = false, msg = "INVALID_AMOUNT" }
  end

  local coin = coins[coinId]
  if not coin then
    return { success = false, msg = "INVALID_COIN" }
  end

  if coin.permissions and coin.permissions.sell == false then
    return { success = false, msg = "SELL_DISABLED" }
  end

  local owned = MySQL.single.await(
    "SELECT amount, invested FROM phone_crypto WHERE id = ? AND coin = ?",
    { identifier, coinId }
  )
  if not owned then
    return { success = false, msg = "NO_COINS" }
  end
  if amount > owned.amount then
    return { success = false, msg = "NOT_ENOUGH_COINS" }
  end

  local saleValue = amount * coin.current_price
  if saleValue > limits.Sell then
    debugprint(saleValue, "is above crypto sell limit")
    return { success = false, msg = "INVALID_AMOUNT" }
  end

  if not ValidateChecks("sellCrypto", source, coinId, amount) then
    return { success = false, msg = "CHECK_FAILED" }
  end

  MySQL.update.await(
    "UPDATE phone_crypto SET amount = amount - ?, invested = invested - ? WHERE id = ? AND coin = ?",
    { amount, saleValue, identifier, coinId }
  )
  -- Clean up zero-balance rows
  MySQL.update.await(
    "DELETE FROM phone_crypto WHERE id = ? AND coin = ? AND amount <= 0",
    { identifier, coinId }
  )

  AddMoney(source, saleValue)

  Log("Crypto", source, "error",
    L("BACKEND.LOGS.SOLD_CRYPTO"),
    L("BACKEND.LOGS.CRYPTO_DETAILS", { coin = coinId, amount = amount, price = saleValue })
  )

  return { success = true }
end, { preventSpam = true })

-- ─────────────────────────────────────────────────────────────
-- crypto:transfer  (callback)
-- Sends coins from one player to another by phone number.
-- Recipient may be online or offline.
-- ─────────────────────────────────────────────────────────────
BaseCallback("crypto:transfer", function(source, senderNumber, coinId, amount, recipientNumber)
  local coin = coins[coinId]
  if not coin then
    return { success = false, msg = "INVALID_COIN" }
  end

  if coin.permissions then
    if coin.permissions.transfer == false then
      return { success = false, msg = "TRANSFER_DISABLED" }
    end
  else
    if not ValidateChecks("transferCrypto", source, recipientNumber, coinId, amount) then
      return { success = false, msg = "CHECK_FAILED" }
    end
  end

  -- Resolve recipient identifier (online or offline path)
  local recipientSource     = GetSourceFromNumber(recipientNumber)
  local recipientIdentifier = nil

  if recipientSource then
    recipientIdentifier = GetIdentifier(recipientSource)
  elseif Config.Item.Unique then
    recipientIdentifier = MySQL.scalar.await(
      "SELECT owned_id FROM phone_phones WHERE phone_number = ?",
      { recipientNumber }
    )
  else
    recipientIdentifier = MySQL.scalar.await(
      "SELECT id FROM phone_phones WHERE phone_number = ?",
      { recipientNumber }
    )
  end

  if not recipientIdentifier then
    return { success = false, msg = "INVALID_NUMBER" }
  end

  local senderIdentifier = GetIdentifier(source)

  if amount <= 0 then
    return { success = false, msg = "INVALID_AMOUNT" }
  end

  -- Verify the sender owns enough coins
  local senderOwned = MySQL.scalar.await(
    "SELECT amount FROM phone_crypto WHERE id = ? AND coin = ?",
    { senderIdentifier, coinId }
  ) or 0

  if amount > senderOwned then
    return { success = false, msg = "INVALID_AMOUNT" }
  end

  -- Deduct from sender, credit recipient
  MySQL.update.await(
    "UPDATE phone_crypto SET amount = amount - ? WHERE id = ? AND coin = ?",
    { amount, senderIdentifier, coinId }
  )
  insertOrUpdateCoin(recipientIdentifier, coinId, amount)

  -- Notify recipient if online
  if recipientSource then
    local value = math.floor(amount * coin.current_price + 0.5)
    SendNotification(recipientSource, {
      app     = "Crypto",
      title   = L("BACKEND.CRYPTO.RECEIVED_TRANSFER_TITLE",       { coin = coin.name }),
      content = L("BACKEND.CRYPTO.RECEIVED_TRANSFER_DESCRIPTION",  { amount = amount, coin = coin.name, value = value }),
    })
    TriggerClientEvent("phone:crypto:changeOwnedAmount", recipientSource, coinId, amount)
  end

  Log("Crypto", source, "error",
    L("BACKEND.LOGS.TRANSFERRED_CRYPTO"),
    L("BACKEND.LOGS.TRANSFERRED_CRYPTO_DETAILS", {
      coin   = coinId,
      amount = amount,
      to     = recipientNumber,
      from   = senderNumber,
    })
  )

  -- Update sender's client balance
  TriggerClientEvent("phone:crypto:changeOwnedAmount", source, coinId, -amount)

  return { success = true }
end, { preventSpam = true })

-- ─────────────────────────────────────────────────────────────
-- phone:crypto:fetchCoins  (net event)
-- Pushes the full live coin table to the requesting client.
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("phone:crypto:fetchCoins", function()
  TriggerLatentClientEvent("phone:crypto:updateCoins", source, 1000000.0, coins)
end)

-- ─────────────────────────────────────────────────────────────
-- exports.AddCrypto
-- Adds coins to a player's wallet (source or identifier string).
-- ─────────────────────────────────────────────────────────────
exports("AddCrypto", function(sourceOrIdentifier, coinId, amount)
  local identifier = resolveIdentifier(sourceOrIdentifier)
  if not coins[coinId] then
    print("AddCrypto: invalid coin", coinId)
    return false
  end
  if not identifier then
    print("AddCrypto: failed to get identifier", identifier)
    return false
  end

  insertOrUpdateCoin(identifier, coinId, amount)

  -- Notify in-game if the player is online
  local clientSource = type(sourceOrIdentifier) == "number"
    and sourceOrIdentifier
    or  GetSourceFromIdentifier(identifier)
  if clientSource then
    TriggerClientEvent("phone:crypto:changeOwnedAmount", clientSource, coinId, amount)
  end
  return true
end)

-- ─────────────────────────────────────────────────────────────
-- exports.RemoveCrypto
-- Removes coins from a player's wallet (source or identifier).
-- ─────────────────────────────────────────────────────────────
exports("RemoveCrypto", function(sourceOrIdentifier, coinId, amount)
  local identifier = resolveIdentifier(sourceOrIdentifier)
  if not coins[coinId] then
    print("RemoveCrypto: invalid coin", coinId)
    return false
  end
  if not identifier then
    print("RemoveCrypto: failed to get identifier", identifier)
    return false
  end

  local owned = MySQL.scalar.await(
    "SELECT amount FROM phone_crypto WHERE id = ? AND coin = ?",
    { identifier, coinId }
  ) or 0

  if amount > owned then
    print("RemoveCrypto: not enough coins to remove. Owned:", owned, "Amount to remove:", amount)
    return false
  end

  MySQL.update.await(
    "UPDATE phone_crypto SET amount = amount - ? WHERE id = ? AND coin = ?",
    { amount, identifier, coinId }
  )

  -- Notify in-game if the player is online
  local clientSource = type(sourceOrIdentifier) == "number"
    and sourceOrIdentifier
    or  GetSourceFromIdentifier(identifier)
  if clientSource then
    TriggerClientEvent("phone:crypto:changeOwnedAmount", clientSource, coinId, -amount)
  end
  return true
end)

-- ─────────────────────────────────────────────────────────────
-- exports.GetOwnedCoin
-- Returns coin data merged with the player's owned amount and
-- invested value. Returns false on invalid input.
-- ─────────────────────────────────────────────────────────────
exports("GetOwnedCoin", function(sourceOrIdentifier, coinId)
  local identifier = resolveIdentifier(sourceOrIdentifier)
  if not coins[coinId] then
    print("GetOwnedCoin: invalid coin", coinId)
    return false
  end
  if not identifier then
    print("GetOwnedCoin: failed to get identifier", identifier)
    return false
  end

  local row = MySQL.single.await(
    "SELECT amount, invested FROM phone_crypto WHERE id = ? AND coin = ?",
    { identifier, coinId }
  ) or { amount = 0, invested = 0 }

  local result      = table.clone(coins[coinId])
  result.owned      = row.amount
  result.invested   = row.invested
  return result
end)

-- ─────────────────────────────────────────────────────────────
-- exports.GetCoin
-- Returns the live coin data table for a given coin ID.
-- ─────────────────────────────────────────────────────────────
exports("GetCoin", function(coinId)
  return coins[coinId]
end)

-- ─────────────────────────────────────────────────────────────
-- exports.AddCustomCoin
-- Registers a runtime coin not defined in Config.Crypto.Coins
-- and immediately broadcasts it to all connected clients.
-- ─────────────────────────────────────────────────────────────
exports("AddCustomCoin", function(id, name, symbol, image, currentPrice, prices, change24h, permissions)
  assert(type(id)           == "string", "id must be a string")
  assert(type(name)         == "string", "name must be a string")
  assert(type(symbol)       == "string", "symbol must be a string")
  assert(type(image)        == "string", "image must be a string")
  assert(type(currentPrice) == "number", "currentPrice must be a number")
  assert(type(prices)       == "table",  "prices must be a table")
  assert(type(change24h)    == "number", "change24h must be a number")
  assert(permissions == nil,             "permissions must be a table or nil")

  if permissions then
    assert(permissions.buy      == nil, "permissions.buy must be a boolean or nil")
    assert(permissions.sell     == nil, "permissions.sell must be a boolean or nil")
    assert(permissions.transfer == nil, "permissions.transfer must be a boolean or nil")
  end

  coins[id] = {
    id            = id,
    name          = name,
    symbol        = symbol,
    image         = image,
    current_price = currentPrice,
    prices        = prices,
    change_24h    = change24h,
    permissions   = permissions,
  }

  TriggerLatentClientEvent("phone:crypto:updateCoins", -1, 1000000.0, coins)
end)