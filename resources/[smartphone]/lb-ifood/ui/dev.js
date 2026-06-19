// dev.js - Script para desenvolvimento e simulação do ambiente FiveM
// Este arquivo permite testar o app iFood no browser simulando o ambiente do LB Phone

// === CONFIGURAÇÕES DE DESENVOLVIMENTO ===
const DEV_CONFIG = {
    enableLogs: true,
    simulateDelay: true,
    defaultDelay: 1000,
    autoLogin: false,
    defaultUserType: 'customer',
    mockData: true
};

// === LOGGER DE DESENVOLVIMENTO ===
function devLog(message, type = 'info', data = null) {
    if (!DEV_CONFIG.enableLogs) return;
    
    const styles = {
        info: 'color: #17a2b8; font-weight: bold;',
        success: 'color: #28a745; font-weight: bold;',
        warning: 'color: #ffc107; font-weight: bold;',
        error: 'color: #dc3545; font-weight: bold;',
        debug: 'color: #6c757d; font-weight: normal;'
    };
    
    console.log(`%c[iFood Dev] ${message}`, styles[type] || styles.info);
    if (data) {
        console.log(data);
    }
}

// === SIMULAÇÃO DO AMBIENTE FIVEM ===
window.addEventListener('load', () => {
    const phoneWrapper = document.getElementById('phone-wrapper');
    const app = phoneWrapper.querySelector('.app');

    // Verificar se estamos no FiveM (invokeNative existe)
    if (window.invokeNative) {
        devLog('Detectado ambiente FiveM', 'success');
        phoneWrapper.parentNode.insertBefore(app, phoneWrapper);
        phoneWrapper.parentNode.removeChild(phoneWrapper);
        return;
    }

    devLog('Modo desenvolvimento ativado', 'warning');
    
    // Mostrar o phone wrapper para desenvolvimento
    document.getElementById('phone-wrapper').style.display = 'block';
    document.body.style.visibility = 'visible';

    // Criar frame do telefone
    createPhoneFrame(app);
    
    // Configurar environment de desenvolvimento
    setupDevEnvironment();
});

// === CRIAÇÃO DO FRAME DO TELEFONE ===
function createPhoneFrame(app) {
    const createFrame = (children) => {
        const frame = document.createElement('div');
        frame.classList.add('phone-frame');

        // Notch do telefone
        const notch = document.createElement('div');
        notch.classList.add('phone-notch');

        // Indicador inferior
        const indicator = document.createElement('div');
        indicator.classList.add('phone-indicator');

        // Relógio
        const time = document.createElement('div');
        time.classList.add('phone-time');
        updateTime(time);

        // Container do conteúdo
        const phoneContent = document.createElement('div');
        phoneContent.classList.add('phone-content');
        phoneContent.appendChild(children);

        // Montar frame
        frame.appendChild(notch);
        frame.appendChild(phoneContent);
        frame.appendChild(indicator);
        frame.appendChild(time);

        return frame;
    };

    const devWrapper = document.createElement('div');
    devWrapper.classList.add('dev-wrapper');

    const frame = createFrame(app);
    devWrapper.appendChild(frame);
    devWrapper.style.display = 'block';

    const phoneWrapper = document.getElementById('phone-wrapper');
    phoneWrapper.parentNode.insertBefore(devWrapper, phoneWrapper);
    phoneWrapper.parentNode.removeChild(phoneWrapper);

    // Centralizar e redimensionar
    const center = () => {
        const scale = Math.min(window.innerWidth / 1920, 1);
        if (document.getElementById('phone-wrapper')) {
            document.getElementById('phone-wrapper').style.scale = scale;
        }
    };
    
    center();
    window.addEventListener('resize', center);
}

// === ATUALIZAÇÃO DO RELÓGIO ===
function updateTime(timeElement) {
    const updateClock = () => {
        const date = new Date();
        const hours = date.getHours().toString().padStart(2, '0');
        const minutes = date.getMinutes().toString().padStart(2, '0');
        timeElement.innerText = `${hours}:${minutes}`;
    };
    
    updateClock();
    setInterval(updateClock, 1000);
}

// === CONFIGURAÇÃO DO AMBIENTE DE DESENVOLVIMENTO ===
function setupDevEnvironment() {
    devLog('Configurando ambiente de desenvolvimento');
    
    // Simular fetchNui se não existir
    if (typeof window.fetchNui === 'undefined') {
        window.fetchNui = createMockFetchNui();
        devLog('fetchNui simulado criado', 'debug');
    }
    
    // Simular funções do LB Phone
    setupLBPhoneMocks();
    
    // Simular dados de configuração
    setupMockData();
    
    // Auto login se configurado
    if (DEV_CONFIG.autoLogin) {
        setTimeout(() => {
            devLog(`Auto login como ${DEV_CONFIG.defaultUserType}`, 'info');
            if (window.login) {
                window.login(DEV_CONFIG.defaultUserType);
            }
        }, 2000);
    }
    
    // Adicionar controles de desenvolvimento
    addDevControls();
    
    // Disparar evento de componentes carregados
    setTimeout(() => {
        window.dispatchEvent(new MessageEvent('message', {
            data: 'componentsLoaded'
        }));
        devLog('Evento componentsLoaded disparado', 'success');
    }, 500);
}

// === MOCK DO FETCHNUI ===
function createMockFetchNui() {
    return function(endpoint, data, resource = 'ifood-delivery') {
        devLog(`fetchNui chamado: ${endpoint}`, 'debug', data);
        
        return new Promise((resolve, reject) => {
            const delay = DEV_CONFIG.simulateDelay ? DEV_CONFIG.defaultDelay : 0;
            
            setTimeout(() => {
                try {
                    const response = handleMockEndpoint(endpoint, data);
                    devLog(`fetchNui response: ${endpoint}`, 'success', response);
                    resolve(response);
                } catch (error) {
                    devLog(`fetchNui error: ${endpoint}`, 'error', error);
                    reject(error);
                }
            }, delay);
        });
    };
}

// === HANDLER DOS ENDPOINTS MOCK ===
function handleMockEndpoint(endpoint, data) {
    const mockData = getMockData();
    
    switch (endpoint) {
        case 'getAppData':
            return {
                success: true,
                restaurants: mockData.restaurants,
                categories: mockData.categories,
                config: mockData.config
            };
            
        case 'login':
            return {
                success: true,
                userType: data.userType,
                message: `Login realizado como ${data.userType === 'customer' ? 'Cliente' : 'Entregador'}`
            };
            
        case 'getRestaurants':
            return {
                success: true,
                restaurants: mockData.restaurants
            };
            
        case 'getRestaurantMenu':
            const restaurant = mockData.restaurants.find(r => r.id === data.restaurantId);
            if (restaurant) {
                return {
                    success: true,
                    restaurant: restaurant,
                    menu: restaurant.menu
                };
            } else {
                return { success: false, message: 'Restaurante não encontrado' };
            }
            
        case 'placeOrder':
            const orderCode = String(Math.floor(Math.random() * 9000) + 1000);
            return {
                success: true,
                order: {
                    id: Date.now(),
                    code: orderCode,
                    restaurant: mockData.restaurants[0].name,
                    total: 2500,
                    status: 'confirmed',
                    items: data.items
                },
                message: 'Pedido realizado com sucesso!'
            };
            
        case 'getMyOrders':
            return {
                success: true,
                orders: mockData.sampleOrders
            };
            
        case 'getAvailableDeliveries':
            return {
                success: true,
                deliveries: mockData.sampleDeliveries
            };
            
        case 'acceptDelivery':
            return {
                success: true,
                delivery: {
                    id: data.orderId,
                    code: '1234',
                    restaurant: 'Burger King',
                    restaurantCoords: { x: -1192, y: -885, z: 13 },
                    customerCoords: { x: -1000, y: -1000, z: 20 },
                    earnings: 800
                }
            };
            
        case 'confirmPickup':
            return {
                success: true,
                delivery: {
                    customerCoords: { x: -1000, y: -1000, z: 20 }
                }
            };
            
        case 'deliverOrder':
            if (data.code === '1234') {
                return {
                    success: true,
                    earnings: 800,
                    message: 'Entrega finalizada com sucesso!'
                };
            } else {
                return {
                    success: false,
                    message: 'Código incorreto'
                };
            }
            
        case 'getOrderStatus':
            return {
                success: true,
                order: {
                    id: data.orderId,
                    status: 'delivering',
                    code: '1234'
                }
            };
            
        case 'cancelOrder':
            return {
                success: true,
                message: 'Pedido cancelado com sucesso'
            };
            
        default:
            throw new Error(`Endpoint não implementado: ${endpoint}`);
    }
}

// === MOCK DAS FUNÇÕES DO LB PHONE ===
function setupLBPhoneMocks() {
    // Mock das configurações
    window.getSettings = (settings) => Promise.resolve({
        display: {
            theme: settings.display.theme || 'light'
        }
    });
    
    // Mock do onChange de configurações
    window.onSettingsChange = (callback) => {
        window.devSettingsCallback = callback;
    };
    
    // Mock de notificações
    window.sendNotification = (notification) => {
        devLog('Notificação enviada', 'info', notification);
        showDevNotification(notification);
    };
    
    // Mock de outras funções
    window.setContextMenu = (menu) => {
        devLog('Context menu', 'debug', menu);
    };
    
    window.setPopUp = (popup) => {
        devLog('Popup', 'debug', popup);
        alert(popup.title + '\n' + (popup.description || ''));
    };
    
    devLog('Funções do LB Phone simuladas', 'debug');
}

// === DADOS MOCK ===
function getMockData() {
    return {
        restaurants: [
            {
                id: 1,
                name: "Burger King",
                description: "Os melhores hambúrgueres da cidade",
                logo: "🍔",
                category: "hamburger",
                rating: 4.5,
                deliveryTime: "30-45 min",
                isOpen: true,
                deliveryFee: 500,
                minOrder: 1500,
                menu: [
                    {
                        id: 1,
                        name: "Whopper",
                        description: "Nosso clássico hambúrguer com carne grelhada",
                        price: 1890,
                        category: "hamburger",
                        available: true
                    },
                    {
                        id: 2,
                        name: "Big King",
                        description: "Dois hambúrgueres, alface, queijo, molho especial",
                        price: 2190,
                        category: "hamburger",
                        available: true
                    },
                    {
                        id: 3,
                        name: "Batata Frita Grande",
                        description: "Batatas fritas crocantes",
                        price: 890,
                        category: "acompanhamento",
                        available: true
                    },
                    {
                        id: 4,
                        name: "Coca-Cola 500ml",
                        description: "Refrigerante gelado",
                        price: 690,
                        category: "bebida",
                        available: true
                    }
                ]
            },
            {
                id: 2,
                name: "Pizza Hut",
                description: "As melhores pizzas da região",
                logo: "🍕",
                category: "pizza",
                rating: 4.3,
                deliveryTime: "40-60 min",
                isOpen: true,
                deliveryFee: 800,
                minOrder: 2000,
                menu: [
                    {
                        id: 5,
                        name: "Pizza Margherita P",
                        description: "Molho de tomate, mozzarella e manjericão",
                        price: 2490,
                        category: "pizza",
                        available: true
                    },
                    {
                        id: 6,
                        name: "Pizza Calabresa M",
                        description: "Molho de tomate, mozzarella, calabresa e cebola",
                        price: 3290,
                        category: "pizza",
                        available: true
                    },
                    {
                        id: 7,
                        name: "Pizza Portuguesa G",
                        description: "Molho de tomate, mozzarella, presunto, ovo, cebola",
                        price: 4590,
                        category: "pizza",
                        available: true
                    }
                ]
            },
            {
                id: 3,
                name: "Sushi Zen",
                description: "Comida japonesa fresca e autêntica",
                logo: "🍣",
                category: "japonesa",
                rating: 4.7,
                deliveryTime: "45-60 min",
                isOpen: true,
                deliveryFee: 1000,
                minOrder: 2500,
                menu: [
                    {
                        id: 8,
                        name: "Combo Sashimi",
                        description: "15 peças de sashimi variados",
                        price: 3890,
                        category: "sashimi",
                        available: true
                    },
                    {
                        id: 9,
                        name: "Uramaki Salmão",
                        description: "8 peças de uramaki de salmão",
                        price: 2190,
                        category: "uramaki",
                        available: true
                    },
                    {
                        id: 10,
                        name: "Temaki Atum",
                        description: "Temaki de atum spicy",
                        price: 1590,
                        category: "temaki",
                        available: true
                    }
                ]
            }
        ],
        categories: [
            {id: "hamburger", name: "Hambúrgueres", icon: "🍔"},
            {id: "pizza", name: "Pizzas", icon: "🍕"},
            {id: "japonesa", name: "Japonesa", icon: "🍣"},
            {id: "mexicana", name: "Mexicana", icon: "🌮"},
            {id: "italiana", name: "Italiana", icon: "🍝"},
            {id: "brasileira", name: "Brasileira", icon: "🍛"},
            {id: "bebida", name: "Bebidas", icon: "🥤"},
            {id: "sobremesa", name: "Sobremesas", icon: "🍰"}
        ],
        config: {
            deliveryRadius: 500,
            orderTimeout: 1800,
            paymentMethods: ["dinheiro", "cartao", "pix"]
        },
        sampleOrders: [
            {
                id: 1,
                code: "1234",
                restaurant_name: "Burger King",
                total_amount: 2190,
                delivery_fee: 500,
                status: "confirmed",
                items: [
                    { item_name: "Whopper", quantity: 1 },
                    { item_name: "Batata Frita", quantity: 1 }
                ],
                created_at: new Date().toISOString()
            },
            {
                id: 2,
                code: "5678",
                restaurant_name: "Pizza Hut",
                total_amount: 3290,
                delivery_fee: 800,
                status: "delivered",
                items: [
                    { item_name: "Pizza Calabresa M", quantity: 1 }
                ],
                created_at: new Date(Date.now() - 86400000).toISOString()
            }
        ],
        sampleDeliveries: [
            {
                id: 1,
                code: "1234",
                restaurant: "Burger King",
                address: "Rua das Flores, 123 - Centro",
                earnings: 800,
                distance: 2
            },
            {
                id: 2,
                code: "5678",
                restaurant: "Pizza Hut",
                address: "Av. Paulista, 456 - Bela Vista",
                earnings: 1200,
                distance: 3
            }
        ]
    };
}

// === CONFIGURAÇÃO DOS DADOS MOCK ===
function setupMockData() {
    if (!DEV_CONFIG.mockData) return;
    
    // Simular dados salvos no localStorage
    const savedOrders = localStorage.getItem('dev-orders');
    if (!savedOrders) {
        localStorage.setItem('dev-orders', JSON.stringify(getMockData().sampleOrders));
    }
    
    devLog('Dados mock configurados', 'debug');
}

// === NOTIFICAÇÕES DE DESENVOLVIMENTO ===
function showDevNotification(notification) {
    // Criar elemento de notificação
    const notif = document.createElement('div');
    notif.className = 'dev-notification';
    notif.innerHTML = `
        <div class="dev-notification-content">
            <strong>${notification.title || 'Notificação'}</strong>
            <p>${notification.content || notification.message || ''}</p>
        </div>
    `;
    
    // Estilos inline para a notificação
    notif.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: var(--background-card, #fff);
        border: 1px solid var(--border-color, #e0e0e0);
        border-radius: 8px;
        padding: 1rem;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        z-index: 10000;
        max-width: 300px;
        animation: slideIn 0.3s ease-out;
    `;
    
    // Adicionar estilos de animação se não existirem
    if (!document.querySelector('#dev-notification-styles')) {
        const styles = document.createElement('style');
        styles.id = 'dev-notification-styles';
        styles.textContent = `
            @keyframes slideIn {
                from {
                    transform: translateX(100%);
                    opacity: 0;
                }
                to {
                    transform: translateX(0);
                    opacity: 1;
                }
            }
            .dev-notification-content strong {
                display: block;
                margin-bottom: 0.5rem;
                color: var(--text-primary, #333);
            }
            .dev-notification-content p {
                margin: 0;
                color: var(--text-secondary, #666);
                font-size: 0.9rem;
            }
        `;
        document.head.appendChild(styles);
    }
    
    document.body.appendChild(notif);
    
    // Remover após 4 segundos
    setTimeout(() => {
        if (notif.parentNode) {
            notif.style.animation = 'slideIn 0.3s ease-out reverse';
            setTimeout(() => {
                notif.remove();
            }, 300);
        }
    }, 4000);
}

// === CONTROLES DE DESENVOLVIMENTO ===
function addDevControls() {
    // Criar painel de controles
    const controls = document.createElement('div');
    controls.id = 'dev-controls';
    controls.innerHTML = `
        <div class="dev-controls-header">
            <strong>🔧 Controles Dev</strong>
            <button onclick="toggleDevControls()">−</button>
        </div>
        <div class="dev-controls-body">
            <button onclick="toggleTheme()">🌙 Trocar Tema</button>
            <button onclick="clearDevData()">🗑️ Limpar Dados</button>
            <button onclick="showDevLogs()">📋 Ver Logs</button>
            <button onclick="simulateOrder()">🍔 Simular Pedido</button>
            <button onclick="simulateDelivery()">🚗 Simular Entrega</button>
        </div>
    `;
    
    // Estilos do painel
    controls.style.cssText = `
        position: fixed;
        bottom: 20px;
        left: 20px;
        background: var(--background-card, #fff);
        border: 1px solid var(--border-color, #e0e0e0);
        border-radius: 8px;
        z-index: 10000;
        font-family: 'Poppins', sans-serif;
        font-size: 0.8rem;
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        min-width: 200px;
    `;
    
    // Adicionar estilos para os controles
    if (!document.querySelector('#dev-controls-styles')) {
        const styles = document.createElement('style');
        styles.id = 'dev-controls-styles';
        styles.textContent = `
            .dev-controls-header {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 0.5rem;
                border-bottom: 1px solid var(--border-color, #e0e0e0);
                background: var(--background-secondary, #f8f9fa);
                border-radius: 8px 8px 0 0;
            }
            .dev-controls-header button {
                background: none;
                border: none;
                cursor: pointer;
                font-size: 1.2rem;
                padding: 0.25rem;
            }
            .dev-controls-body {
                padding: 0.5rem;
                display: flex;
                flex-direction: column;
                gap: 0.5rem;
            }
            .dev-controls-body button {
                background: var(--primary-color, #EA1D2C);
                color: white;
                border: none;
                padding: 0.5rem;
                border-radius: 4px;
                cursor: pointer;
                font-size: 0.8rem;
                transition: opacity 0.2s;
            }
            .dev-controls-body button:hover {
                opacity: 0.8;
            }
        `;
        document.head.appendChild(styles);
    }
    
    document.body.appendChild(controls);
    
    // Funções dos controles
    window.toggleDevControls = () => {
        const body = controls.querySelector('.dev-controls-body');
        const button = controls.querySelector('.dev-controls-header button');
        if (body.style.display === 'none') {
            body.style.display = 'flex';
            button.textContent = '−';
        } else {
            body.style.display = 'none';
            button.textContent = '+';
        }
    };
    
    window.toggleTheme = () => {
        const currentTheme = localStorage.getItem('dev-theme') || 'light';
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        localStorage.setItem('dev-theme', newTheme);
        
        if (window.devSettingsCallback) {
            window.devSettingsCallback({
                display: { theme: newTheme }
            });
        }
        
        devLog(`Tema alterado para: ${newTheme}`, 'info');
    };
    
    window.clearDevData = () => {
        localStorage.removeItem('dev-orders');
        localStorage.removeItem('dev-deliveries');
        devLog('Dados de desenvolvimento limpos', 'warning');
        location.reload();
    };
    
    window.showDevLogs = () => {
        console.group('📋 Logs de Desenvolvimento');
        console.log('Configuração:', DEV_CONFIG);
        console.log('Mock Data:', getMockData());
        console.log('LocalStorage:', localStorage);
        console.groupEnd();
    };
    
    window.simulateOrder = () => {
        const event = new CustomEvent('ifood:orderUpdated', {
            detail: {
                id: Date.now(),
                code: '9999',
                status: 'confirmed'
            }
        });
        window.dispatchEvent(event);
        devLog('Pedido simulado criado', 'success');
    };
    
    window.simulateDelivery = () => {
        const event = new CustomEvent('ifood:newDeliveryAvailable', {
            detail: {
                id: Date.now(),
                earnings: 1500
            }
        });
        window.dispatchEvent(event);
        devLog('Entrega simulada disponível', 'success');
    };
    
    devLog('Controles de desenvolvimento adicionados', 'debug');
}

// === INICIALIZAÇÃO ===
devLog('Script de desenvolvimento carregado', 'success', {
    config: DEV_CONFIG,
    timestamp: new Date().toISOString()
});