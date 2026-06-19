local OrdersTable = Config.Database.Tables.orders
local DeliverersTable = Config.Database.Tables.deliverers
local OrderItemsTable = Config.Database.Tables.order_items

local function getPassport()
    local source = source
    local passport = vRP.Passport(source)
    if not passport then
        return nil, { success = false, message = "Usuário inválido" }
    end
    return passport
end

local function getSourceFromPassport(passport)
    if not passport then
        return nil
    end

    return vRP.Source(passport)
end

local function getPhoneNumberFromPassport(passport)
    if not passport then
        return nil
    end

    local lastPhone = MySQL.scalar.await("SELECT phone_number FROM phone_last_phone WHERE id = ? LIMIT 1", { passport })
    if lastPhone and lastPhone ~= "" then
        return tostring(lastPhone)
    end

    local phone = MySQL.scalar.await([[
        SELECT phone_number
        FROM phone_phones
        WHERE id = ?
        ORDER BY last_seen DESC, id DESC
        LIMIT 1
    ]], { passport })

    if phone and phone ~= "" then
        return tostring(phone)
    end

    return nil
end

local function takePayment(passport, paymentMethod, amount)
    amount = math.floor(tonumber(amount) or 0)
    paymentMethod = tostring(paymentMethod or "")

    if amount <= 0 then
        return false, "Valor invÃ¡lido"
    end

    if paymentMethod == "dinheiro" or paymentMethod == "cash" then
        if vRP.TakeItem(passport, "dollars", amount, true) then
            return true
        end

        return false, "Saldo insuficiente em dinheiro"
    end

    if paymentMethod == "cartao" or paymentMethod == "pix" or paymentMethod == "bank" then
        if vRP.PaymentBank(passport, amount, true) then
            return true
        end

        return false, "Saldo bancÃ¡rio insuficiente"
    end

    if vRP.PaymentFull(passport, amount) then
        return true
    end

    return false, "Saldo insuficiente"
end

local function refundPayment(passport, paymentMethod, amount)
    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        return
    end

    if paymentMethod == "dinheiro" then
        vRP.GenerateItem(passport, "dollars", amount, true)
        return
    end

    vRP.GiveBank(passport, amount)
end

local function payDeliverer(passport, amount)
    amount = math.floor(tonumber(amount) or 0)

    if amount > 0 then
        vRP.GenerateItem(passport, "dollars", amount, true)
    end
end

local function chargePenalty(passport, amount)
    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        return false
    end

    return vRP.PaymentBank(passport, amount, true) or vRP.TakeItem(passport, "dollars", amount, true)
end

local function getRestaurantById(id)
    for _, restaurant in ipairs(Config.Restaurants) do
        if restaurant.id == id then
            return restaurant
        end
    end
    return nil
end

local function buildOrderObject(row, items)
    local orderItems = {}
    if items then
        for _, item in ipairs(items) do
            orderItems[#orderItems + 1] = {
                item_name = item.item_name,
                quantity = item.quantity
            }
        end
    end

    return {
        id = row.id,
        code = row.code,
        restaurant_name = row.restaurant_name,
        total_amount = row.total_amount,
        delivery_fee = row.delivery_fee,
        status = row.status,
        items = orderItems,
        created_at = row.created_at
    }
end

local function getOrderById(orderId)
    local result = MySQL.query.await("SELECT * FROM `" .. OrdersTable .. "` WHERE id = ?", { orderId })
    if result and result[1] then
        return result[1]
    end
    return nil
end

local function getOrderItems(orderId)
    local result = MySQL.query.await("SELECT item_name, quantity FROM `" .. OrderItemsTable .. "` WHERE order_id = ?", { orderId })
    return result or {}
end

local function updateOrderStatus(orderId, status)
    MySQL.update.await("UPDATE `" .. OrdersTable .. "` SET status = ?, updated_at = NOW() WHERE id = ?", { status, orderId })
end

local function getPlayerCoords(playerSource)
    local ped = GetPlayerPed(playerSource)
    if not ped or ped == 0 then
        return nil
    end
    local coords = GetEntityCoords(ped)
    return { x = coords.x, y = coords.y, z = coords.z }
end

local function calculateDelivererEarnings(total)
    local percentage = tonumber(Config.Deliverer.EarningsPercentage) or 0
    local bonus = tonumber(Config.Deliverer.BonusPerDelivery) or 0
    local amount = math.floor(total * percentage) + bonus
    if amount < 0 then
        amount = 0
    end
    return amount
end

local function fetchDeliverer(user_id)
    local result = MySQL.query.await("SELECT * FROM `" .. DeliverersTable .. "` WHERE user_id = ?", { user_id })
    if result and result[1] then
        return result[1]
    end
    return nil
end

local function setDelivererAvailabilityDB(user_id, available)
    local now = os.date("%Y-%m-%d %H:%M:%S")
    local row = fetchDeliverer(user_id)
    local availableInt = available and 1 or 0

    if row then
        MySQL.update.await("UPDATE `" .. DeliverersTable .. "` SET is_available = ?, last_active_at = ? WHERE user_id = ?", {
            availableInt,
            now,
            user_id
        })
    else
        MySQL.insert.await("INSERT INTO `" .. DeliverersTable .. "` (user_id, is_available, last_active_at) VALUES (?, ?, ?)", {
            user_id,
            availableInt,
            now
        })
    end
end

local function ensureTables()
    if not Config.createTables then
        return
    end

    MySQL.query("CREATE TABLE IF NOT EXISTS `" .. OrdersTable .. "` (" ..
        "id INT AUTO_INCREMENT PRIMARY KEY," ..
        "user_id INT NOT NULL," ..
        "restaurant_id INT NOT NULL," ..
        "restaurant_name VARCHAR(255) NOT NULL," ..
        "total_amount INT NOT NULL," ..
        "delivery_fee INT NOT NULL," ..
        "status VARCHAR(32) NOT NULL," ..
        "code VARCHAR(8) NOT NULL," ..
        "payment_method VARCHAR(32) NOT NULL," ..
        "customer_x DOUBLE," ..
        "customer_y DOUBLE," ..
        "customer_z DOUBLE," ..
        "deliverer_id INT DEFAULT NULL," ..
        "deliverer_earnings INT DEFAULT 0," ..
        "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," ..
        "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" ..
    ")", {})

    MySQL.query("CREATE TABLE IF NOT EXISTS `" .. OrderItemsTable .. "` (" ..
        "id INT AUTO_INCREMENT PRIMARY KEY," ..
        "order_id INT NOT NULL," ..
        "item_id VARCHAR(64) NOT NULL," ..
        "item_name VARCHAR(255) NOT NULL," ..
        "quantity INT NOT NULL," ..
        "price INT NOT NULL," ..
        "FOREIGN KEY (order_id) REFERENCES `" .. OrdersTable .. "`(id) ON DELETE CASCADE" ..
    ")", {})

    MySQL.query("CREATE TABLE IF NOT EXISTS `" .. DeliverersTable .. "` (" ..
        "user_id INT PRIMARY KEY," ..
        "is_available TINYINT(1) NOT NULL DEFAULT 0," ..
        "active_order_id INT DEFAULT NULL," ..
        "last_active_at TIMESTAMP NULL DEFAULT NULL" ..
    ")", {})
end

if MySQL and MySQL.ready then
    MySQL.ready(function()
        ensureTables()
    end)
else
    ensureTables()
end

function src.getAppData()
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    local restaurants = {}
    for _, restaurant in ipairs(Config.Restaurants) do
        restaurants[#restaurants + 1] = {
            id = restaurant.id,
            name = restaurant.name,
            description = restaurant.description,
            logo = restaurant.logo,
            category = restaurant.category,
            rating = restaurant.rating,
            deliveryTime = restaurant.deliveryTime,
            isOpen = restaurant.isOpen,
            deliveryFee = restaurant.deliveryFee,
            minOrder = restaurant.minOrder
        }
    end

    local categories = Config.FoodCategories or {}

    local config = {
        deliveryRadius = Config.DeliveryRadius,
        orderTimeout = Config.OrderTimeout,
        paymentMethods = Config.Payment and Config.Payment.Methods or {}
    }

    return {
        success = true,
        restaurants = restaurants,
        categories = categories,
        config = config
    }
end

function src.loginUser(userType)
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    if userType ~= Config.UserTypes.CUSTOMER and userType ~= Config.UserTypes.DELIVERER then
        return { success = false, message = "Tipo de usuário inválido" }
    end

    if userType == Config.UserTypes.DELIVERER then
        setDelivererAvailabilityDB(user_id, true)
    end

    return {
        success = true,
        userType = userType,
        message = "Login realizado como " .. (userType == Config.UserTypes.CUSTOMER and "Cliente" or "Entregador")
    }
end

function src.placeOrder(data)
    local source = source
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    if not data or type(data) ~= "table" then
        return { success = false, message = "Dados do pedido inválidos" }
    end

    local restaurantId = tonumber(data.restaurantId)
    local items = data.items or {}
    local paymentMethod = tostring(data.paymentMethod or "")

    if not restaurantId or #items == 0 then
        return { success = false, message = "Restaurante ou itens inválidos" }
    end

    local restaurant = getRestaurantById(restaurantId)
    if not restaurant then
        return { success = false, message = "Restaurante não encontrado" }
    end

    local total = 0
    local dbItems = {}

    for _, item in ipairs(items) do
        local itemId = item.itemId
        local quantity = tonumber(item.quantity) or 0

        if quantity > 0 then
            local menuItem = Config.GetMenuItem(restaurantId, itemId)
            if not menuItem or not menuItem.available then
                return { success = false, message = "Item inválido no pedido" }
            end

            local price = tonumber(menuItem.price) or 0
            total = total + (price * quantity)
            dbItems[#dbItems + 1] = {
                item_id = itemId,
                item_name = menuItem.name,
                quantity = quantity,
                price = price
            }
        end
    end

    if total <= 0 then
        return { success = false, message = "Total do pedido inválido" }
    end

    local customerCoords = getPlayerCoords(source) or { x = restaurant.coords.x, y = restaurant.coords.y, z = restaurant.coords.z }
    local distance = 1000.0
    local deliveryFee = Config.CalculateDeliveryFee(distance, restaurantId)

    local status = Config.OrderStatus.CONFIRMED
    local code = Config.GenerateOrderCode()

    local totalToPay = total + deliveryFee

    local paid, paymentError = takePayment(user_id, paymentMethod, totalToPay)
    if not paid then
        return { success = false, message = paymentError }
    end

    local orderId = MySQL.insert.await("INSERT INTO `" .. OrdersTable .. "` (user_id, restaurant_id, restaurant_name, total_amount, delivery_fee, status, code, payment_method, customer_x, customer_y, customer_z) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        user_id,
        restaurantId,
        restaurant.name,
        total,
        deliveryFee,
        status,
        code,
        paymentMethod,
        customerCoords.x,
        customerCoords.y,
        customerCoords.z
    })

    if not orderId or orderId <= 0 then
        return { success = false, message = "Erro ao salvar pedido" }
    end

    for _, item in ipairs(dbItems) do
        MySQL.insert.await("INSERT INTO `" .. OrderItemsTable .. "` (order_id, item_id, item_name, quantity, price) VALUES (?, ?, ?, ?, ?)", {
            orderId,
            item.item_id,
            item.item_name,
            item.quantity,
            item.price
        })
    end

    local orderRow = getOrderById(orderId)
    local orderItems = getOrderItems(orderId)
    local orderObject = buildOrderObject(orderRow, orderItems)

    TriggerClientEvent("ifood:orderUpdated", source, {
        id = orderObject.id,
        status = orderObject.status,
        code = orderObject.code
    })

    return {
        success = true,
        order = orderObject,
        message = "Pedido realizado com sucesso!"
    }
end

function src.getMyOrders()
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    local result = MySQL.query.await("SELECT * FROM `" .. OrdersTable .. "` WHERE user_id = ? ORDER BY created_at DESC", { user_id })
    local orders = {}

    for _, row in ipairs(result or {}) do
        local items = getOrderItems(row.id)
        orders[#orders + 1] = buildOrderObject(row, items)
    end

    return {
        success = true,
        orders = orders
    }
end

function src.getOrderStatus(orderId)
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId then
        return { success = false, message = "Pedido inválido" }
    end

    local row = getOrderById(orderId)
    if not row or (tonumber(row.user_id) ~= tonumber(user_id) and tonumber(row.deliverer_id) ~= tonumber(user_id)) then
        return { success = false, message = "Pedido não encontrado" }
    end

    return {
        success = true,
        order = {
            id = row.id,
            status = row.status,
            code = row.code
        }
    }
end

function src.cancelOrder(orderId)
    local source = source
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId then
        return { success = false, message = "Pedido inválido" }
    end

    local row = getOrderById(orderId)
    if not row or tonumber(row.user_id) ~= tonumber(user_id) then
        return { success = false, message = "Pedido não encontrado" }
    end

    if row.status == Config.OrderStatus.DELIVERED or row.status == Config.OrderStatus.CANCELLED then
        return { success = false, message = "Não é possível cancelar este pedido" }
    end

    updateOrderStatus(orderId, Config.OrderStatus.CANCELLED)

    refundPayment(user_id, row.payment_method, (tonumber(row.total_amount) or 0) + (tonumber(row.delivery_fee) or 0))
    if row.deliverer_id then
        local delivererSource = getSourceFromPassport(tonumber(row.deliverer_id))
        if delivererSource then
            vCLIENT.anulateOrderClient(delivererSource, orderId)
        end
    end

    TriggerClientEvent("ifood:orderUpdated", source, {
        id = row.id,
        status = Config.OrderStatus.CANCELLED,
        code = row.code
    })

    return {
        success = true,
        message = "Pedido cancelado com sucesso"
    }
end

function src.setDelivererAvailability(isAvailable)
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    local available = not not isAvailable
    setDelivererAvailabilityDB(user_id, available)

    return {
        success = true,
        isAvailable = available
    }
end

function src.getAvailableDeliveries()
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    local deliverer = fetchDeliverer(user_id)
    if deliverer and deliverer.is_available == 0 then
        return { success = true, deliveries = {} }
    end

    local result = MySQL.query.await("SELECT * FROM `" .. OrdersTable .. "` WHERE status = ? AND (deliverer_id IS NULL OR deliverer_id = 0)", {
        Config.OrderStatus.CONFIRMED
    })

    local deliveries = {}

    for _, row in ipairs(result or {}) do
        local restaurant = getRestaurantById(row.restaurant_id)
        if restaurant then
            local earnings = calculateDelivererEarnings(row.total_amount + row.delivery_fee)
            deliveries[#deliveries + 1] = {
                id = row.id,
                code = row.code,
                restaurant = restaurant.name,
                earnings = earnings,
                distance = 2000
            }
        end
    end

    return {
        success = true,
        deliveries = deliveries
    }
end

function src.acceptDelivery(orderId)
    local source = source
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId then
        return { success = false, message = "Entrega inválida" }
    end

    local row = getOrderById(orderId)
    if not row or row.status ~= Config.OrderStatus.CONFIRMED or (row.deliverer_id and tonumber(row.deliverer_id) ~= 0) then
        return { success = false, message = "Entrega não está disponível" }
    end

    MySQL.update.await("UPDATE `" .. OrdersTable .. "` SET deliverer_id = ?, status = ? WHERE id = ?", {
        user_id,
        Config.OrderStatus.PICKUP,
        orderId
    })

    local restaurant = getRestaurantById(row.restaurant_id)
    if not restaurant then
        return { success = false, message = "Restaurante não encontrado para esta entrega" }
    end

    local earnings = calculateDelivererEarnings(row.total_amount + row.delivery_fee)

    local delivery = {
        id = orderId,
        code = row.code,
        restaurant = restaurant.name,
        restaurantCoords = {
            x = restaurant.coords.x,
            y = restaurant.coords.y,
            z = restaurant.coords.z
        },
        customerCoords = {
            x = row.customer_x or restaurant.coords.x,
            y = row.customer_y or restaurant.coords.y,
            z = row.customer_z or restaurant.coords.z
        },
        earnings = earnings,
        status = Config.OrderStatus.PICKUP
    }

    local customerSource = getSourceFromPassport(tonumber(row.user_id))
    if customerSource then
        TriggerClientEvent("ifood:orderUpdated", customerSource, {
            id = row.id,
            status = Config.OrderStatus.PICKUP,
            code = row.code
        })
    end

    return {
        success = true,
        delivery = delivery
    }
end

function src.getActiveDelivery()
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    local result = MySQL.query.await("SELECT * FROM `" .. OrdersTable .. "` WHERE deliverer_id = ? AND status <> ? AND status <> ? ORDER BY created_at DESC LIMIT 1", {
        user_id,
        Config.OrderStatus.DELIVERED,
        Config.OrderStatus.CANCELLED
    })

    local row = result and result[1]
    if not row then
        return { success = true, delivery = nil }
    end

    local restaurant = getRestaurantById(row.restaurant_id)
    local earnings = calculateDelivererEarnings(row.total_amount + row.delivery_fee)

    local delivery = {
        id = row.id,
        code = row.code,
        restaurant = restaurant and restaurant.name or row.restaurant_name,
        customer_phone = getPhoneNumberFromPassport(tonumber(row.user_id)),
        earnings = earnings,
        status = row.status,
        customerCoords = {
            x = row.customer_x,
            y = row.customer_y,
            z = row.customer_z
        }
    }

    return {
        success = true,
        delivery = delivery
    }
end

function src.cancelActiveDelivery(orderId)
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId then
        return { success = false, message = "Entrega inválida" }
    end

    local row = getOrderById(orderId)
    if not row or tonumber(row.deliverer_id) ~= tonumber(user_id) then
        return { success = false, message = "Entrega não encontrada" }
    end

    if row.status == Config.OrderStatus.DELIVERED or row.status == Config.OrderStatus.CANCELLED then
        return { success = false, message = "Entrega já finalizada" }
    end

    MySQL.update.await("UPDATE `" .. OrdersTable .. "` SET deliverer_id = NULL, status = ? WHERE id = ?", {
        Config.OrderStatus.CONFIRMED,
        orderId
    })

    local customerSource = getSourceFromPassport(tonumber(row.user_id))
    if customerSource then
        TriggerClientEvent("ifood:orderUpdated", customerSource, {
            id = row.id,
            status = Config.OrderStatus.CONFIRMED,
            code = row.code
        })
    end

    return {
        success = true,
        message = "Entrega cancelada com sucesso"
    }
end

function src.confirmPickup(orderId)
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId then
        return { success = false, message = "Entrega inválida" }
    end

    local row = getOrderById(orderId)
    if not row or tonumber(row.deliverer_id) ~= tonumber(user_id) then
        return { success = false, message = "Entrega não encontrada" }
    end

    if row.status ~= Config.OrderStatus.PICKUP and row.status ~= Config.OrderStatus.CONFIRMED then
        return { success = false, message = "Não é possível confirmar esta entrega" }
    end

    updateOrderStatus(orderId, Config.OrderStatus.DELIVERING)

    local customerSource = getSourceFromPassport(tonumber(row.user_id))
    if customerSource then
        TriggerClientEvent("ifood:orderUpdated", customerSource, {
            id = row.id,
            status = Config.OrderStatus.DELIVERING,
            code = row.code
        })
    end

    return {
        success = true,
        delivery = {
            customerCoords = {
                x = row.customer_x,
                y = row.customer_y,
                z = row.customer_z
            }
        }
    }
end

function src.deliverOrder(orderId, code)
    local source = source
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId or not code then
        return { success = false, message = "Dados inválidos" }
    end

    local row = getOrderById(orderId)
    if not row or tonumber(row.deliverer_id) ~= tonumber(user_id) then
        return { success = false, message = "Entrega não encontrada" }
    end

    if row.status == Config.OrderStatus.DELIVERED then
        return { success = false, message = "Entrega já finalizada" }
    end

    if tostring(code) ~= tostring(row.code) then
        return { success = false, message = "Código incorreto" }
    end

    local coords = getPlayerCoords(source)
    if coords and row.customer_x and row.customer_y and row.customer_z then
        local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(row.customer_x, row.customer_y, row.customer_z))
        if distance > 30.0 then
            return { success = false, message = "Você precisa estar próximo ao cliente" }
        end
    end

    local earnings = calculateDelivererEarnings(row.total_amount + row.delivery_fee)

    MySQL.update.await("UPDATE `" .. OrdersTable .. "` SET status = ?, deliverer_earnings = ? WHERE id = ?", {
        Config.OrderStatus.DELIVERED,
        earnings,
        orderId
    })

    payDeliverer(user_id, earnings)

    local customerSource = getSourceFromPassport(tonumber(row.user_id))
    if customerSource then
        TriggerClientEvent("ifood:orderUpdated", customerSource, {
            id = row.id,
            status = Config.OrderStatus.DELIVERED,
            code = row.code
        })
    end

    return {
        success = true,
        earnings = earnings,
        message = "Entrega finalizada com sucesso"
    }
end

function src.anulateOrder(orderId)
    local source = source
    local user_id, err = getPassport()
    if not user_id then
        return err
    end

    orderId = tonumber(orderId)
    if not orderId then
        return { success = false, message = "Pedido inválido" }
    end

    local row = getOrderById(orderId)
    if not row or tonumber(row.user_id) ~= tonumber(user_id) then
        return { success = false, message = "Pedido não encontrado" }
    end

    if row.status == Config.OrderStatus.DELIVERED or row.status == Config.OrderStatus.CANCELLED then
        return { success = false, message = "Pedido já finalizado" }
    end

    updateOrderStatus(orderId, Config.OrderStatus.CANCELLED)

    local fine = tonumber(Config.Payment.MinDeliveryFee) or 0
    if fine > 0 then
        chargePenalty(user_id, fine)
    end

    if row.deliverer_id then
        local delivererSource = getSourceFromPassport(tonumber(row.deliverer_id))
        if delivererSource then
            local bonus = tonumber(Config.Deliverer.BonusPerDelivery) or 0
            if bonus > 0 then
                payDeliverer(tonumber(row.deliverer_id), bonus)
            end
            vCLIENT.anulateOrderClient(delivererSource, orderId)
        end
    end

    vCLIENT.anulateOrderClient(source, orderId)

    return {
        success = true,
        message = "Pedido anulado"
    }
end