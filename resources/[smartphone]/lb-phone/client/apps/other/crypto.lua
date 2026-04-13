if not (Config.Crypto and Config.Crypto.Enabled) then
  return
end

-- ── Module-level state ────────────────────────────────────────
local coinCache  = {}   -- ordered list of coin data objects shown in the UI
local isBusy     = false -- prevents overlapping buy/sell/transfer requests

-- ─────────────────────────────────────────────────────────────
-- findCoin  (internal helper)
-- Linear search through coinCache by coin id.
-- Returns (index, coinData) on success, or false on miss.
-- ─────────────────────────────────────────────────────────────
local function findCoin(coinId)
  for i, coin in ipairs(coinCache) do
    if coin.id == coinId then
      return i, coin
    end
  end
  return false
end

-- ─────────────────────────────────────────────────────────────
-- syncQBit  (internal helper)
-- Pulls QBit data from the QB-Core framework integration and
-- inserts/updates the "qbit" entry in coinCache. Only runs
-- when Config.Crypto.QBit is enabled and framework is "qb".
-- ─────────────────────────────────────────────────────────────
local function syncQBit()
  if not (Config.Crypto.QBit and Config.Framework == "qb") then
    return
  end

  local qbit = GetQBit()

  -- Build the price history array from QB history entries
  local prices = {}
  for _, entry in ipairs(qbit.History) do
    prices[#prices + 1] = entry.PreviousWorth
    prices[#prices + 1] = entry.NewWorth
  end

  -- If no history exists, seed with 10 random values around current worth
  if #qbit.History == 0 then
    for i = 1, 10 do
      prices[i] = qbit.Worth + math.random(-10, 10)
    end
  end

  -- Calculate 24 h change from first/last history entries
  local change24h = 0
  if #qbit.History > 0 then
    local newest = qbit.History[#qbit.History].NewWorth
    local oldest = qbit.History[1].PreviousWorth
    change24h    = newest - oldest
  end

  local index = findCoin("qbit")
  local slot  = index or (#coinCache + 1)

  coinCache[slot] = {
    id            = "qbit",
    name          = "QBit",
    symbol        = "qbit",
    image         = "https://avatars.githubusercontent.com/u/81791099?s=200&v=4",
    current_price = qbit.Worth,
    prices        = prices,
    change_24h    = change24h,
    owned         = qbit.Portfolio,
  }
end

-- ─────────────────────────────────────────────────────────────
-- buyCoin  (internal helper)
-- Sends a buy request to the server (or to BuyQBit for qbit)
-- and optimistically updates the local cache on success.
-- ─────────────────────────────────────────────────────────────
local function buyCoin(coinId, amount)
  local result

  if coinId == "qbit" then
    result = BuyQBit and BuyQBit(amount)
  else
    result = AwaitCallback("crypto:buy", coinId, amount)
  end

  isBusy = false
  if not result or not result.success then return result end

  local _, coin = findCoin(coinId)
  if not coin then return result end

  -- Update local cache optimistically
  coin.owned    = (coin.owned    or 0) + (amount / coin.current_price)
  coin.invested = (coin.invested or 0) + amount

  return result
end

-- ─────────────────────────────────────────────────────────────
-- sellCoin  (internal helper)
-- Sends a sell request and updates the local cache on success.
-- ─────────────────────────────────────────────────────────────
local function sellCoin(coinId, amount)
  local result

  if coinId == "qbit" then
    result = SellQBit and SellQBit(amount)
  else
    result = AwaitCallback("crypto:sell", coinId, amount)
  end

  isBusy = false
  if not result or not result.success then return result end

  local _, coin = findCoin(coinId)
  if not coin or not coin.invested or not coin.owned then return result end

  coin.invested = coin.invested - (amount * coin.current_price)
  coin.owned    = coin.owned    - amount

  return result
end

-- ─────────────────────────────────────────────────────────────
-- transferCoin  (internal helper)
-- Sends a transfer request and updates the local cache on success.
-- ─────────────────────────────────────────────────────────────
local function transferCoin(coinId, amount, recipientNumber)
  local result

  if coinId == "qbit" then
    result = TransferQBit and TransferQBit(amount)
  else
    result = AwaitCallback("crypto:transfer", coinId, amount, recipientNumber)
  end

  isBusy = false
  if not result or not result.success then return result end

  local _, coin = findCoin(coinId)
  if not coin or not coin.invested or not coin.owned then return result end

  coin.invested = coin.invested - (amount * coin.current_price)
  coin.owned    = coin.owned    - amount

  return result
end

-- ─────────────────────────────────────────────────────────────
-- RegisterNUICallback "Crypto"
-- Central NUI handler for all crypto actions dispatched from
-- the phone UI: buy, sell, transfer, get, openedApp, closedApp.
-- ─────────────────────────────────────────────────────────────
RegisterNUICallback("Crypto", function(data, cb)
  local action = data.action
  debugprint("Crypto:" .. (action or ""))

  -- Spam guard for mutating actions
  if action == "buy" or action == "sell" or action == "transfer" then
    if isBusy then
      return cb({ success = false, msg = "BUSY" })
    end
    isBusy = true
  end

  if action == "buy" then
    return cb(buyCoin(data.coin, data.amount))

  elseif action == "sell" then
    return cb(sellCoin(data.coin, data.amount))

  elseif action == "transfer" then
    return cb(transferCoin(data.coin, data.amount, data.number))

  elseif action == "get" then
    -- Sync QBit first, then ask the server for the latest coin list
    syncQBit()
    TriggerServerEvent("phone:crypto:fetchCoins")
    return cb(coinCache)

  elseif action == "openedApp" then
    TriggerServerEvent("phone:crypto:setAppOpen", true)

  elseif action == "closedApp" then
    TriggerServerEvent("phone:crypto:setAppOpen", false)
  end

  cb("ok")
end)

-- ─────────────────────────────────────────────────────────────
-- FetchCryptoCoins  (exported function)
-- Fetches the full coin list from the server, rebuilds the
-- local cache, and pushes the updated list to the React UI.
-- ─────────────────────────────────────────────────────────────
local function fetchCryptoCoins()
  local serverCoins = AwaitCallback("crypto:get")
  if not serverCoins then return end

  table.wipe(coinCache)

  for _, coin in pairs(serverCoins) do
    coinCache[#coinCache + 1] = coin
  end

  SendReactMessage("crypto:updateCoins", coinCache)
end

FetchCryptoCoins = fetchCryptoCoins

-- ─────────────────────────────────────────────────────────────
-- Startup thread
-- Waits for the framework to finish loading, then performs the
-- initial coin fetch so the cache is populated before any NUI
-- requests arrive.
-- ─────────────────────────────────────────────────────────────
CreateThread(function()
  while not FrameworkLoaded do Wait(500) end
  fetchCryptoCoins()
end)

-- ─────────────────────────────────────────────────────────────
-- phone:crypto:updateCoins  (net event)
-- Receives a full coin map from the server (sent as a latent
-- event). Merges price/history updates into existing entries
-- and appends any brand-new coins, then notifies the React UI.
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("phone:crypto:updateCoins", function(updatedCoins)
  -- Update price data for coins already in the cache
  for _, coin in ipairs(coinCache) do
    local updated = updatedCoins[coin.id]
    if updated then
      coin.current_price = updated.current_price
      coin.change_24h    = updated.change_24h
      coin.prices        = updated.prices
    end
  end

  -- Append any coins that aren't in the cache yet
  for coinId, coinData in pairs(updatedCoins) do
    if not findCoin(coinId) then
      coinCache[#coinCache + 1] = coinData
    end
  end

  debugprint("updated crypto cache")
  SendReactMessage("crypto:updateCoins", coinCache)
end)

-- ─────────────────────────────────────────────────────────────
-- phone:crypto:changeOwnedAmount  (net event)
-- Fine-grained update: adjusts a single coin's owned amount
-- without requiring a full cache refresh.
-- ─────────────────────────────────────────────────────────────
RegisterNetEvent("phone:crypto:changeOwnedAmount", function(coinId, delta)
  local _, coin = findCoin(coinId)
  if not coin then return end

  coin.owned = (coin.owned or 0) + delta
  debugprint("updated crypto cache", coinId, delta, coin.owned)
  SendReactMessage("crypto:updateCoins", coinCache)
end)

-- ─────────────────────────────────────────────────────────────
-- exports.GetCoinValue
-- Returns the current price of a coin by ID, or nil if unknown.
-- ─────────────────────────────────────────────────────────────
exports("GetCoinValue", function(coinId)
  local _, coin = findCoin(coinId)
  return coin and coin.current_price
end)

-- ─────────────────────────────────────────────────────────────
-- exports.GetCryptoWallet
-- Returns the full coinCache array (all coins with owned/invested).
-- ─────────────────────────────────────────────────────────────
exports("GetCryptoWallet", function()
  return coinCache
end)

-- ─────────────────────────────────────────────────────────────
-- exports.GetOwnedCoin
-- Returns the coin data object for a specific coin ID, or nil.
-- ─────────────────────────────────────────────────────────────
exports("GetOwnedCoin", function(coinId)
  local _, coin = findCoin(coinId)
  return coin
end)