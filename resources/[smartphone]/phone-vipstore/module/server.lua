local purchaseLocks = {}
local redeemLocks = {}

local function now()
    return os.time()
end

local function trim(value, maxLength)
    value = tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if maxLength and #value > maxLength then
        value = value:sub(1, maxLength)
    end
    return value
end

local function passport(source)
    return vRP.Passport(source)
end

local function getProduct(productId)
    productId = trim(productId, 80)
    for _, product in ipairs(Config.Products or {}) do
        if product.id == productId then
            return product
        end
    end
end

local function itemExists(item)
    if type(ItemExist) ~= 'function' then
        return true
    end
    return ItemExist(item) and true or false
end

local function itemName(item, fallback)
    if type(ItemName) == 'function' then
        local name = ItemName(item)
        if name and name ~= 'Deletado' then
            return name
        end
    end
    return fallback or item
end

local function itemImage(item, fallback)
    if item and item ~= '' then
        return ('nui://vrp/config/inventory/%s.png'):format(item)
    end

    return fallback or ''
end

local function canReceive(Passport, item, amount)
    amount = parseInt(amount, true)

    if not itemExists(item) then
        return false, 'invalid_item'
    end

    if vRP.MaxItens(Passport, item, amount) then
        return false, 'max_items'
    end

    if vRP.CheckWeight and not vRP.CheckWeight(Passport, item, amount) then
        return false, 'no_space'
    end

    local inventory = vRP.Inventory(Passport) or {}
    for slot = 0, 100 do
        local index = tostring(slot)
        if not inventory[index] or inventory[index].item == item then
            return true
        end
    end

    return false, 'no_slot'
end

local function notify(source, title, content)
    TriggerClientEvent('phone-vipstore:notify', source, title, content)
end

local function sendWebhook(title, description, color)
    local webhook = Config.Webhook
    if type(webhook) ~= 'string' or webhook == '' or not webhook:find('^https://') then
        return
    end

    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        embeds = {{
            title = title,
            description = description,
            color = color or 5814783,
            footer = { text = 'VIP Store' }
        }}
    }), { ['Content-Type'] = 'application/json' })
end

local function normalizeProduct(product)
    local item = trim(product.item, 80)
    return {
        id = trim(product.id, 80),
        category = trim(product.category or 'destaques', 40),
        name = trim(product.name, 80),
        description = trim(product.description, 220),
        item = item,
        itemName = itemName(item, product.name),
        amount = parseInt(product.amount, true),
        price = parseInt(product.price, true),
        image = itemImage(item),
        featured = product.featured and true or false,
        available = itemExists(item)
    }
end

local function setupDatabase()
    exports.oxmysql:update_async([[
        CREATE TABLE IF NOT EXISTS `phone_vipstore_orders` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `passport` INT NOT NULL,
            `product_id` VARCHAR(80) NOT NULL,
            `product_name` VARCHAR(120) NOT NULL,
            `item` VARCHAR(120) NOT NULL,
            `amount` INT NOT NULL,
            `price` INT NOT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'pending',
            `created_at` INT NOT NULL,
            `redeemed_at` INT DEFAULT NULL,
            INDEX `idx_phone_vipstore_passport` (`passport`),
            INDEX `idx_phone_vipstore_status` (`status`)
        )
    ]], {})
end

CreateThread(setupDatabase)

local function enrichOrder(row)
    row.itemName = itemName(row.item, row.product_name)
    row.image = itemImage(row.item)
    return row
end

local function getRows(Passport)
    local rows = exports.oxmysql:query_async([[
        SELECT * FROM `phone_vipstore_orders`
        WHERE `passport` = ?
        ORDER BY `id` DESC
        LIMIT 100
    ]], { Passport }) or {}

    for _, row in ipairs(rows) do
        enrichOrder(row)
    end

    return rows
end

local function getBalance(Passport)
    local identity = vRP.Identity(Passport)
    if identity and identity.License then
        return vRP.UserGemstone(identity.License) or 0
    end
    return 0
end

srv.getData = function()
    local source = source
    local Passport = passport(source)
    if not Passport then
        return { ok = false, products = {}, categories = {}, pending = {}, history = {}, balance = 0 }
    end

    local products = {}
    for _, product in ipairs(Config.Products or {}) do
        products[#products + 1] = normalizeProduct(product)
    end

    local pending = {}
    local history = {}
    for _, row in ipairs(getRows(Passport)) do
        if row.status == 'pending' then
            pending[#pending + 1] = row
        else
            history[#history + 1] = row
        end
    end

    return {
        ok = true,
        products = products,
        categories = Config.Categories or {},
        pending = pending,
        history = history,
        balance = getBalance(Passport)
    }
end

srv.buyItem = function(data)
    local source = source
    local Passport = passport(source)
    if not Passport or type(data) ~= 'table' then
        return { ok = false, error = 'invalid_request' }
    end

    if purchaseLocks[Passport] then
        return { ok = false, error = 'busy' }
    end

    local product = getProduct(data.productId)
    if not product then
        return { ok = false, error = 'invalid_product' }
    end

    local clean = normalizeProduct(product)
    if clean.price <= 0 or clean.amount <= 0 or not clean.available then
        return { ok = false, error = 'invalid_product' }
    end

    purchaseLocks[Passport] = true

    if not vRP.PaymentGems(Passport, clean.price) then
        purchaseLocks[Passport] = nil
        notify(source, 'VIP Store', 'Diamantes insuficientes para comprar este item.')
        return { ok = false, error = 'no_diamonds', balance = getBalance(Passport) }
    end

    local orderId = exports.oxmysql:insert_async([[
        INSERT INTO `phone_vipstore_orders` (passport, product_id, product_name, item, amount, price, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)
    ]], { Passport, clean.id, clean.name, clean.item, clean.amount, clean.price, now() })

    purchaseLocks[Passport] = nil

    notify(source, 'Compra aprovada', 'Seu item foi enviado para Pendentes. Resgate quando tiver espaco no inventario.')
    sendWebhook('Compra VIP', ('Passaporte: %s\nProduto: %s\nItem: %sx %s\nValor: %s diamantes'):format(Passport, clean.name, clean.amount, clean.item, clean.price), 5814783)

    return { ok = true, id = orderId, balance = getBalance(Passport) }
end

local function redeemOrder(source, Passport, orderId)
    orderId = tonumber(orderId)
    if not orderId then
        return { ok = false, error = 'invalid_order' }
    end

    local rows = exports.oxmysql:query_async('SELECT * FROM `phone_vipstore_orders` WHERE `id` = ? AND `passport` = ? AND `status` = ? LIMIT 1', { orderId, Passport, 'pending' }) or {}
    local order = rows[1]
    if not order then
        return { ok = false, error = 'not_found' }
    end

    local allowed, reason = canReceive(Passport, order.item, order.amount)
    if not allowed then
        notify(source, 'Inventario sem espaco', 'Libere espaco/peso e tente resgatar novamente. O item continua pendente.')
        return { ok = false, error = reason or 'no_space', pending = true }
    end

    local updated = exports.oxmysql:update_async('UPDATE `phone_vipstore_orders` SET `status` = ?, `redeemed_at` = ? WHERE `id` = ? AND `passport` = ? AND `status` = ?', { 'redeemed', now(), orderId, Passport, 'pending' })
    if not updated or updated <= 0 then
        return { ok = false, error = 'already_processed' }
    end

    vRP.GiveItem(Passport, order.item, order.amount, true)
    notify(source, 'Item resgatado', ('Voce recebeu %sx %s.'):format(order.amount, itemName(order.item, order.product_name)))
    sendWebhook('Resgate VIP', ('Passaporte: %s\nPedido: #%s\nItem: %sx %s'):format(Passport, orderId, order.amount, order.item), 3066993)

    return { ok = true }
end

srv.redeemPending = function(data)
    local source = source
    local Passport = passport(source)
    if not Passport or type(data) ~= 'table' then
        return { ok = false, error = 'invalid_request' }
    end

    if redeemLocks[Passport] then
        return { ok = false, error = 'busy' }
    end

    redeemLocks[Passport] = true
    local result = redeemOrder(source, Passport, data.id)
    redeemLocks[Passport] = nil
    return result
end

srv.redeemAll = function()
    local source = source
    local Passport = passport(source)
    if not Passport then
        return { ok = false, error = 'invalid_request' }
    end

    if redeemLocks[Passport] then
        return { ok = false, error = 'busy' }
    end

    redeemLocks[Passport] = true
    local rows = exports.oxmysql:query_async('SELECT `id` FROM `phone_vipstore_orders` WHERE `passport` = ? AND `status` = ? ORDER BY `id` ASC', { Passport, 'pending' }) or {}
    local redeemed = 0
    local blocked = 0

    for _, row in ipairs(rows) do
        local result = redeemOrder(source, Passport, row.id)
        if result.ok then
            redeemed = redeemed + 1
        else
            blocked = blocked + 1
            if result.pending then
                break
            end
        end
    end

    redeemLocks[Passport] = nil
    return { ok = true, redeemed = redeemed, blocked = blocked }
end


