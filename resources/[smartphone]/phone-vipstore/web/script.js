const API = 'https://phone-vipstore';

let state = {
  products: [],
  categories: [],
  pending: [],
  history: [],
  balance: 0,
  category: 'all',
  busy: false,
};

function post(event, data = {}) {
  return new Promise((resolve) => {
    $.post(`${API}/${event}`, JSON.stringify(data), resolve).fail(() => resolve(false));
  });
}

function money(value) {
  return Number(value || 0).toLocaleString('pt-BR');
}

function dateLabel(timestamp) {
  if (!timestamp) return '--';
  return new Date(Number(timestamp) * 1000).toLocaleString('pt-BR', {
    day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit'
  });
}

function imageSrc(product) {
  const image = product && product.image ? product.image : '';
  if (/^(https?:|nui:)\/\//.test(image)) return image;
  return image;
}

function itemImageTag(product) {
  const src = imageSrc(product);
  if (!src) return '<span class="item-placeholder"><i class="fa-solid fa-box"></i></span>';
  return `<img src="${src}" alt="${product.name || product.product_name || product.item || 'Item'}" />`;
}

function toast(message, type = 'info') {
  const el = document.getElementById('toast');
  el.className = `toast ${type}`;
  el.textContent = message;
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => el.classList.add('hidden'), 2600);
}

function setView(view) {
  document.querySelectorAll('.tab').forEach((button) => button.classList.toggle('active', button.dataset.view === view));
  document.querySelectorAll('.view').forEach((screen) => screen.classList.toggle('active', screen.id === `${view}-view`));
}

function renderCategories() {
  const wrap = document.getElementById('categories');
  const categories = [{ id: 'all', name: 'Todos' }, ...state.categories];
  wrap.innerHTML = categories.map((category) => `
    <button class="chip ${state.category === category.id ? 'active' : ''}" data-category="${category.id}">${category.name}</button>
  `).join('');
}

function renderProducts() {
  const wrap = document.getElementById('products');
  const products = state.products.filter((product) => state.category === 'all' || product.category === state.category);

  if (!products.length) {
    wrap.innerHTML = empty('Nenhum item nessa categoria.');
    return;
  }

  wrap.innerHTML = products.map((product) => `
    <article class="item-card ${product.featured ? 'featured' : ''}">
      <div class="item-media">
        ${itemImageTag(product)}
        <span class="qty">x${product.amount}</span>
      </div>
      <div class="item-info">
        <strong>${product.name}</strong>
        <p>${product.description || product.itemName}</p>
      </div>
      <div class="item-footer">
        <span class="price"><i class="fa-solid fa-gem"></i>${money(product.price)}</span>
        <button class="buy-btn" data-product="${product.id}" ${product.available ? '' : 'disabled'}>${product.available ? 'Comprar' : 'Indisponivel'}</button>
      </div>
    </article>
  `).join('');
}

function rowStatus(row) {
  if (row.status === 'redeemed') return 'Resgatado';
  if (row.status === 'pending') return 'Pendente';
  return row.status || 'Compra';
}

function renderPending() {
  document.getElementById('pending-count').textContent = state.pending.length;
  const wrap = document.getElementById('pending-list');

  if (!state.pending.length) {
    wrap.innerHTML = empty('Nenhum item pendente. Suas compras aguardando resgate aparecem aqui.');
    return;
  }

  wrap.innerHTML = state.pending.map((row) => `
    <article class="order-card">
      <div class="order-icon item-picture">${itemImageTag(row)}</div>
      <div>
        <strong>${row.product_name}</strong>
        <p>x${row.amount} ${row.itemName || row.item} - ${dateLabel(row.created_at)}</p>
      </div>
      <button class="redeem-btn" data-id="${row.id}">Resgatar</button>
    </article>
  `).join('');
}

function renderHistory() {
  const wrap = document.getElementById('history-list');
  if (!state.history.length) {
    wrap.innerHTML = empty('Historico vazio por enquanto.');
    return;
  }

  wrap.innerHTML = state.history.map((row) => `
    <article class="order-card history">
      <div class="order-icon item-picture">${itemImageTag(row)}</div>
      <div>
        <strong>${row.product_name}</strong>
        <p>x${row.amount} ${row.itemName || row.item} - ${money(row.price)} diamantes</p>
      </div>
      <span>${rowStatus(row)}</span>
    </article>
  `).join('');
}

function empty(message) {
  return `<div class="empty"><i class="fa-solid fa-box-open"></i><p>${message}</p></div>`;
}

function render() {
  document.getElementById('balance').textContent = money(state.balance);
  renderCategories();
  renderProducts();
  renderPending();
  renderHistory();
}

async function loadData() {
  const data = await post('getData');
  if (!data || data.ok === false) {
    toast('Nao foi possivel carregar a VIP Store.', 'error');
    return;
  }

  state.products = data.products || [];
  state.categories = data.categories || [];
  state.pending = data.pending || [];
  state.history = data.history || [];
  state.balance = data.balance || 0;
  render();
}

async function buy(productId) {
  if (state.busy) return;
  state.busy = true;
  const response = await post('buyItem', { productId });
  state.busy = false;

  if (response && response.ok) {
    toast('Compra enviada para Pendentes.', 'success');
    await loadData();
    setView('pending');
    return;
  }

  const errors = {
    no_diamonds: 'Diamantes insuficientes.',
    invalid_product: 'Produto invalido ou indisponivel.',
    busy: 'Aguarde a compra anterior finalizar.',
  };
  toast(errors[response && response.error] || 'Compra nao aprovada.', 'error');
  if (response && response.balance !== undefined) state.balance = response.balance;
  render();
}

async function redeem(id) {
  if (state.busy) return;
  state.busy = true;
  const response = await post('redeemPending', { id });
  state.busy = false;

  if (response && response.ok) {
    toast('Item resgatado no inventario.', 'success');
  } else if (response && (response.error === 'no_space' || response.error === 'no_slot' || response.error === 'max_items')) {
    toast('Sem espaco no inventario. O item continua pendente.', 'error');
  } else {
    toast('Nao foi possivel resgatar agora.', 'error');
  }

  await loadData();
}

async function redeemAll() {
  if (state.busy) return;
  state.busy = true;
  const response = await post('redeemAll');
  state.busy = false;

  if (response && response.ok) {
    toast(`${response.redeemed || 0} item(ns) resgatado(s).`, response.blocked > 0 ? 'info' : 'success');
  } else {
    toast('Nao foi possivel resgatar tudo.', 'error');
  }

  await loadData();
}

document.addEventListener('click', (event) => {
  const tab = event.target.closest('.tab');
  if (tab) setView(tab.dataset.view);

  const chip = event.target.closest('.chip');
  if (chip) {
    state.category = chip.dataset.category;
    render();
  }

  const buyButton = event.target.closest('.buy-btn');
  if (buyButton && !buyButton.disabled) buy(buyButton.dataset.product);

  const redeemButton = event.target.closest('.redeem-btn');
  if (redeemButton) redeem(redeemButton.dataset.id);
});

document.getElementById('refresh').addEventListener('click', loadData);
document.getElementById('redeem-all').addEventListener('click', redeemAll);

loadData();



