Config = {}

Config.App = {
    name = 'VIP Store',
    description = 'Loja VIP por diamantes',
    developer = 'zVegas',
    defaultApp = true,
    size = 37600
}

Config.Webhook = ''

Config.Categories = {
    { id = 'alimentos', name = 'Alimentos' },
    { id = 'utilitarios', name = 'Utilitarios' },
    { id = 'mochilas', name = 'Mochilas' }
}

-- As imagens sao geradas automaticamente usando ItemIndex(item):
-- nui://vrp/config/inventory/<Index>.png
Config.Products = {
    {
        id = 'vip_agua',
        category = 'alimentos',
        name = 'Pack de Agua',
        description = 'Agua para manter a rotina da cidade em dia.',
        item = 'water',
        amount = 6,
        price = 18,
        featured = true
    },
    {
        id = 'vip_lanche',
        category = 'alimentos',
        name = 'Combo Lanche',
        description = 'Sanduiches prontos para levar no trabalho ou viagem.',
        item = 'sandwich',
        amount = 6,
        price = 24
    },
    {
        id = 'vip_hamburger',
        category = 'alimentos',
        name = 'Combo Hamburger',
        description = 'Refeicao rapida para quem vive na correria.',
        item = 'hamburger',
        amount = 4,
        price = 28
    },
    {
        id = 'vip_cafe',
        category = 'alimentos',
        name = 'Cafe para Viagem',
        description = 'Um reforco simples para comecar o turno.',
        item = 'coffeecup',
        amount = 4,
        price = 20
    },
    {
        id = 'vip_reparo',
        category = 'utilitarios',
        name = 'Kit de Reparo',
        description = 'Ferramentas basicas para reparar seu veiculo.',
        item = 'repairkit01',
        amount = 1,
        price = 75,
        featured = true
    },
    {
        id = 'vip_radio',
        category = 'utilitarios',
        name = 'Radio Comunicador',
        description = 'Comunicacao simples para equipes e servicos.',
        item = 'radio',
        amount = 1,
        price = 55
    },
    {
        id = 'vip_mochila_p',
        category = 'mochilas',
        name = 'Mochila Pequena',
        description = 'Mais espaco para carregar itens essenciais.',
        item = 'backpackp',
        amount = 1,
        price = 180
    },
    {
        id = 'vip_mochila_m',
        category = 'mochilas',
        name = 'Mochila Media',
        description = 'Boa escolha para quem trabalha longe da garagem.',
        item = 'backpackm',
        amount = 1,
        price = 260,
        featured = true
    },
    {
        id = 'vip_mochila_g',
        category = 'mochilas',
        name = 'Mochila Grande',
        description = 'Capacidade alta para rotas, mecanicos e viagens.',
        item = 'backpackg',
        amount = 1,
        price = 360
    }
}
