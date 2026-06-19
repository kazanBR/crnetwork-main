-- config.lua - iFood Delivery App
Config = {}

-- Configurações Gerais
Config.createTables = true -- Define se as tabelas do banco de dados devem ser criadas automaticamente
Config.Debug = false
Config.UseNotifications = true
Config.DeliveryRadius = 500.0 -- Raio máximo de entrega em metros
Config.OrderTimeout = 1800 -- Tempo limite do pedido em segundos (30 min)
Config.DeliveryTimeout = 3600 -- Tempo limite da entrega em segundos (60 min)

-- Configurações de Pagamento
Config.Payment = {
    Methods = {"dinheiro", "cartao", "pix"},
    MinDeliveryFee = 500, 
    pricePerKm = 900 

}

-- Configurações dos Entregadores
Config.Deliverer = {
    RequiredItems = {"mochila_delivery"}, -- Itens necessários para ser entregador
    EarningsPercentage = 0.15, -- 15% do valor do pedido para o entregador
    BonusPerDelivery = 200, -- Bônus fixo por entrega (R$ 2,00)
    MaxActiveDeliveries = 3, -- Máximo de entregas simultâneas
    RequiredVehicles = {"faggio", "pcj", "sanchez"}, -- Veículos permitidos para entrega

}

-- Localização dos Restaurantes
Config.Restaurants = {
    -- {
    --     id = 1,
    --     name = "Burger King",
    --     description = "Os melhores hambúrgueres da cidade",
    --     logo = "https://logoeps.com/wp-content/uploads/2013/02/burger-king-vector-logo.png",
    --     category = "hamburger",
    --     rating = 4.5,
    --     deliveryTime = "30-45 min",
    --     isOpen = true,
    --     coords = vector3(2710.63,3440.33,55.79),
    --     deliveryFee = 600,
    --     minOrder = 200,
        
    --     menu = {
    --         {
    --             id = "whooper",
    --             name = "Whooper",
    --             description = "Nosso clássico hambúrguer com carne grelhada",
    --             price = 49,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "hamburger",
    --             available = true
    --         },
    --         {
    --             id = "big_king",
    --             name = "Big King",
    --             description = "Dois hambúrgueres, alface, queijo, molho especial",
    --             price = 55,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "hamburger",
    --             available = true
    --         },
    --         {
    --             id = "batata_frita",
    --             name = "Batata Frita",
    --             description = "Batatas fritas crocantes",
    --             price = 20,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "acompanhamento",
    --             available = true
    --         },
    --         {
    --             id = "cola",
    --             name = "Coca-Cola 500ml",
    --             description = "Refrigerante gelado",
    --             price = 15,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         },
    --         {
    --             id = "water",
    --             name = "Agua Mineral 500ml",
    --             description = "Água mineral gelada",
    --             price = 10,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         }
    --     }
    -- },

    -- {
    --     id = 2,
    --     name = "Sub way",
    --     description = "Os melhores hambúrgueres da cidade",
    --     logo = "https://logoeps.com/wp-content/uploads/2013/02/burger-king-vector-logo.png",
    --     category = "hamburger",
    --     rating = 4.5,
    --     deliveryTime = "30-45 min",
    --     isOpen = true,
    --     coords = vector3(2716.9,3437.69,55.91),
    --     deliveryFee = 500,
    --     minOrder = 200,
        
    --     menu = {
    --         {
    --             id = "sandwitch_30",
    --             name = "Sandwiche 30cm",
    --             description = "Nosso clássico hambúrguer com carne grelhada",
    --             price = 55,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "hamburger",
    --             available = true
    --         },
    --         {
    --             id = "sandwitch_15",
    --             name = "Sandwiche 15cm",
    --             description = "Dois hambúrgueres, alface, queijo, molho especial",
    --             price = 35,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "hamburger",
    --             available = true
    --         },

    --         {
    --             id = "cola",
    --             name = "Coca-Cola 500ml",
    --             description = "Refrigerante gelado",
    --             price = 15,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         },
    --         {
    --             id = "water",
    --             name = "Agua Mineral 500ml",
    --             description = "Água mineral gelada",
    --             price = 10,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         }
    --     }
    -- },

    {
        id = 1,
        name = "Mc Donalds",
        description = "Os melhores hambúrgueres da cidade",
        logo = "https://logoeps.com/wp-content/uploads/2013/02/burger-king-vector-logo.png",
        category = "hamburger",
        rating = 4.5,
        deliveryTime = "30-45 min",
        isOpen = true,
        coords = vector3(-81.61,27.96,72.94),
        deliveryFee = 300,
        minOrder = 200,
        
        menu = {
            {
                id = "quarteirao",
                name = "Quarteirão com Queijo",
                description = "Nosso clássico hambúrguer com carne grelhada",
                price = 39,
                image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
                category = "hamburger",
                available = true
            },
            {
                id = "big_mac",
                name = "BigMac",
                description = "Dois hambúrgueres, alface, queijo, molho especial",
                price = 51,
                image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
                category = "hamburger",
                available = true
            },
            {
                id = "cola",
                name = "Coca-Cola 500ml",
                description = "Refrigerante gelado",
                price = 15,
                image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
                category = "bebida",
                available = true
            },
            {
                id = "water",
                name = "Agua Mineral 500ml",
                description = "Água mineral gelada",
                price = 10,
                image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
                category = "bebida",
                available = true
            }       
        }
    }, 

    -- {
    --     id = 4,
    --     name = "Havan",
    --     description = "Os melhores hambúrgueres da cidade",
    --     logo = "https://logoeps.com/wp-content/uploads/2013/02/burger-king-vector-logo.png",
    --     category = "utilidades",
    --     rating = 4.5,
    --     deliveryTime = "30-45 min",
    --     isOpen = true,
    --     coords = vector3(-1192.17, -885.17, 13.98),
    --     deliveryFee = 250,
    --     minOrder = 100,
        
    --     menu = {
    --         {
    --             id = "repairkit",
    --             name = "Sanduiche Clássico",
    --             description = "Ferramenta para reparos leves em veículos",
    --             price = 1000,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "utilidades",
    --             available = true
    --         },
    --         {
    --             id = "wrench",
    --             name = "Chave Inglesa",
    --             description = "Ferramenta para apertar parafusos",
    --             price = 1300,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "utilidades",
    --             available = true
    --         },
    --         {
    --             id = "energydrink",
    --             name = "Energetico",
    --             description = "Bebida que acelera o seu coração e te deixa mais feliz",
    --             price = 400,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         },
    --         {
    --             id = "whiskey",
    --             name = "Whiskey",
    --             description = "Bebida alcoólica destilada",
    --             price = 115,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         },
    --         {
    --             id = "tequila",
    --             name = "Tequila",
    --             description = "Bebida alcoólica destilada",
    --             price = 120,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         },
    --         {
    --             id = "vodka",
    --             name = "Vodka",
    --             description = "Bebida alcoólica destilada",
    --             price = 70,
    --             image = "https://cache-backend-mcd.mcdonaldscupones.com/media/image/product$kJXQfHjt/200/200/original?country=br",
    --             category = "bebida",
    --             available = true
    --         },
    --     }
    -- },  

}

-- Categorias de Comida
Config.FoodCategories = {
    {id = "hamburger", name = "Hambúrgueres", icon = "🍔"},
    {id = "pizza", name = "Pizzas", icon = "🍕"},
    {id = "japonesa", name = "Japonesa", icon = "🍣"},
    {id = "mexicana", name = "Mexicana", icon = "🌮"},
    {id = "italiana", name = "Italiana", icon = "🍝"},
    {id = "brasileira", name = "Brasileira", icon = "🍛"},
    {id = "bebida", name = "Bebidas", icon = "🥤"},
    {id = "sobremesa", name = "Sobremesas", icon = "🍰"}
}

-- Status dos Pedidos
Config.OrderStatus = {
    PENDING = "pending",           -- Aguardando confirmação
    CONFIRMED = "confirmed",       -- Confirmado pelo restaurante
    PREPARING = "preparing",       -- Em preparo
    READY = "ready",              -- Pronto para entrega
    PICKUP = "pickup",            -- Coletado pelo entregador
    DELIVERING = "delivering",     -- Em rota de entrega
    DELIVERED = "delivered",       -- Entregue
    CANCELLED = "cancelled"        -- Cancelado
}

-- Tipos de Usuário
Config.UserTypes = {
    CUSTOMER = "customer",
    DELIVERER = "deliverer",
    RESTAURANT = "restaurant"
}

-- Configurações do Banco de Dados
Config.Database = {
    Tables = {
        orders = "ifood_orders",
        deliverers = "ifood_deliverers", 
        restaurants = "ifood_restaurants",
        order_items = "ifood_order_items",
        deliveries = "ifood_deliveries"
    }
}

-- Funções Utilitárias
function Config.GetRestaurantById(id)
    for _, restaurant in ipairs(Config.Restaurants) do
        if restaurant.id == id then
            return restaurant
        end
    end
    return nil
end

function Config.GetMenuItem(restaurantId, itemId)
    local restaurant = Config.GetRestaurantById(restaurantId)
    if restaurant then
        for _, item in ipairs(restaurant.menu) do
            if item.id == itemId then
                return item
            end
        end
    end
    return nil
end


function Config.CalculateDeliveryFee(distance, restaurantId)
    local pricePerKm = tonumber(Config.Payment.pricePerKm) or 0

    local restaurant = Config.GetRestaurantById(restaurantId)

    local baseFee = Config.Payment.MinDeliveryFee

    return parseInt(distance / 1000 * pricePerKm + baseFee)
end

function Config.FormatPrice(price)
    return string.format("R$ %d,00", price)
end

function Config.GenerateOrderCode()
    return string.format("%04d", math.random(1000, 9999))
end

return Config