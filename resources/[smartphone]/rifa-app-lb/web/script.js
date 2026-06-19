// ==========================================================
// Helpers
// ==========================================================
function esc(s){
  return String(s ?? "")
    .replaceAll("&","&amp;")
    .replaceAll("<","&lt;")
    .replaceAll(">","&gt;")
    .replaceAll('"',"&quot;")
    .replaceAll("'","&#039;");
}


function GetResNameSafe() {
  if (typeof GetParentResourceName === "function") return GetParentResourceName();


  const host = (window.location && window.location.host) ? window.location.host : "";
  const clean = host.split(":")[0];
  if (clean.startsWith("cfx-nui-")) return clean.replace("cfx-nui-", "");

  return "rifa-app-lb";
}

function postNui(eventName, data, cb) {
  const res = GetResNameSafe();
  $.post(`https://${res}/${eventName}`, JSON.stringify(data || {}), function (resp) {
    cb && cb(resp);
  });
}

// ==========================================================
// State
// ==========================================================
const state = {
  view: "home",
  userData: null,
  activeRaffles: [],
  myVehicles: [],
  winners: [],

  myTickets: [],
  selectedVehicle: null,
  selectedRaffle: null,
buyQty: 1,
buying: false,

};

// ==========================================================
// DOM
// ==========================================================
const el = {
  headerTitle: document.getElementById("headerTitle"),
  btnBack: document.getElementById("btnBack"),
  btnProfile: document.getElementById("btnProfile"),
  brandIcon: document.getElementById("brandIcon"),

  vHome: document.getElementById("view-home"),
  vSettings: document.getElementById("view-settings"),
  vCreate: document.getElementById("view-create_raffle"),
  vForm: document.getElementById("view-form_raffle"),
  vPlaceholder: document.getElementById("view-placeholder"),

  activeList: document.getElementById("activeRafflesList"),
  activeEmpty: document.getElementById("activeRafflesEmpty"),

  detranWrap: document.getElementById("detranCardWrap"),

  vehiclesList: document.getElementById("myVehiclesList"),
  vehiclesEmpty: document.getElementById("myVehiclesEmpty"),

  raffleImage: document.getElementById("raffle-image"),
  rafflePrice: document.getElementById("raffle-price"),
  raffleTotal: document.getElementById("raffle-total"),
  btnPublish: document.getElementById("btnPublish"),
  selectedVehicleInfo: document.getElementById("selectedVehicleInfo"),


  vMyTickets: document.getElementById("view-my_tickets"),
vWinners: document.getElementById("view-winners"),

myTicketsList: document.getElementById("myTicketsList"),
myTicketsEmpty: document.getElementById("myTicketsEmpty"),
myTicketsCount: document.getElementById("myTicketsCount"),
ticketsSearch: document.getElementById("ticketsSearch"),

winnersList: document.getElementById("winnersList"),
winnersEmpty: document.getElementById("winnersEmpty"),
winnersCount: document.getElementById("winnersCount"),

buyModal: document.getElementById("buyModal"),
buyTitle: document.getElementById("buyTitle"),
buyImage: document.getElementById("buyImage"),
buyPrice: document.getElementById("buyPrice"),
buyTotal: document.getElementById("buyTotal"),
buyConfirm: document.getElementById("buyConfirm"),
qtyMinus: document.getElementById("qtyMinus"),
qtyPlus: document.getElementById("qtyPlus"),
qtyValue: document.getElementById("qtyValue"),
buyMsg: document.getElementById("buyMsg"),



  placeholderText: document.getElementById("placeholderText"),
};

// ==========================================================
// Views
// ==========================================================
function loadWinners(){
  postNui("getWinners", {}, function (data) {
    state.winners = Array.isArray(data) ? data : [];
    renderWinners();
  });
}


function showView(name){
  state.view = name;

  el.vHome.classList.add("hidden");
  el.vSettings.classList.add("hidden");
  el.vCreate.classList.add("hidden");
  el.vForm.classList.add("hidden");
  el.vPlaceholder.classList.add("hidden");
  el.vMyTickets.classList.add("hidden");
el.vWinners.classList.add("hidden");


  // header
  const back = (name !== "home");
  el.btnBack.classList.toggle("hidden", !back);
  el.btnProfile.classList.toggle("hidden", back);
  el.brandIcon.classList.toggle("hidden", back);

  if (name === "home") el.headerTitle.textContent = "RIFAS PRO";
  else if (name === "settings") el.headerTitle.textContent = "Menus";
  else if (name === "create_raffle") el.headerTitle.textContent = "Sua Garagem";
  else if (name === "form_raffle") el.headerTitle.textContent = "Nova Rifa";
  else if (name === "my_tickets") el.headerTitle.textContent = "Meus Números";
else if (name === "winners") el.headerTitle.textContent = "Ganhadores";

  else el.headerTitle.textContent = "Em breve";
  

  if (name === "home") el.vHome.classList.remove("hidden");
  else if (name === "settings") el.vSettings.classList.remove("hidden");
  else if (name === "create_raffle") el.vCreate.classList.remove("hidden");
  else if (name === "form_raffle") el.vForm.classList.remove("hidden");
  else if (name === "my_tickets") el.vMyTickets.classList.remove("hidden");
else if (name === "winners") el.vWinners.classList.remove("hidden");

  else el.vPlaceholder.classList.remove("hidden");
}

function goBack(){
  if (state.view === "settings") return showView("home");
  if (state.view === "create_raffle") return showView("settings");
  if (state.view === "form_raffle") return showView("create_raffle");
  if (state.view === "my_tickets") return showView("settings");
  if (state.view === "winners") return showView("settings");
  return showView("home");
}


// ==========================================================
// Render
// ==========================================================
function renderHome(){
  const list = state.activeRaffles || [];
  el.activeList.innerHTML = "";

  if (!list.length){
    el.activeEmpty.classList.remove("hidden");
    return;
  }
  el.activeEmpty.classList.add("hidden");

  list.forEach((r) => {
    const sold = Number(r.sold_tickets || 0);
    const total = Math.max(1, Number(r.total_tickets || 1));
    const pct = Math.min(100, Math.max(0, (sold/total)*100));

    const div = document.createElement("div");
    div.className = "card";
    div.innerHTML = `
      <div class="img-top">
        <img src="${esc(r.image_url || "")}" alt="">
        <div class="img-grad"></div>
      </div>
      <div class="card-body">
        <div class="row">
          <div style="min-width:0">
            <div style="font-size:14px;font-weight:900;text-transform:uppercase;font-style:italic;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
              ${esc(r.vehicle_name || "Veículo")}
            </div>
          </div>
          <div class="mono" style="font-weight:900;color:var(--orange);">R$ ${esc(r.price ?? "0")}</div>
        </div>

        <div class="bar"><div style="width:${pct}%;"></div></div>

        <div class="row" style="margin-top:10px;">
          <div class="tiny">Vendedor: #${esc(r.passport ?? "-")}</div>
          <div class="tiny">${Math.floor(pct)}%</div>
        </div>
      </div>
    `;
    el.activeList.appendChild(div);


      div.addEventListener("click", () => {
  openBuyModal(r);
});
  });



}


function renderVehicles(){
  const list = state.myVehicles || [];
  el.vehiclesList.innerHTML = "";

  if (!list.length){
    el.vehiclesEmpty.classList.remove("hidden");
    return;
  }
  el.vehiclesEmpty.classList.add("hidden");

  list.forEach((car) => {
    const can = !!car.canRaffle;
    const status = String(car.status || "");
    const ok = status.toLowerCase() === "regular";

    const row = document.createElement("div");
    row.className = `vehicle-row ${can ? "" : "disabled"}`;
    row.innerHTML = `
      <div class="vehicle-left">
        <div class="icon-box ${can ? "" : "red"}">🚗</div>
        <div>
          <p class="veh-name">${esc(car.name || "Veículo")}</p>
          <div class="veh-plate">${esc(car.plate || "")}</div>
        </div>
      </div>
      <div class="status-pill ${ok ? "status-ok" : "status-bad"}">${esc(status || "Indefinido")}</div>
    `;

    if (can){
      row.addEventListener("click", () => {
        state.selectedVehicle = car;
        el.selectedVehicleInfo.textContent = `Veículo: ${car.name} • Placa: ${car.plate} • Model: ${car.model}`;
        showView("form_raffle");
      });
    }

    el.vehiclesList.appendChild(row);
  });
}












function normalizeTicket(t){

  const number = t.number ?? t.ticket ?? t.ticket_number ?? t.num ?? t.id ?? "-";
  const vehicle = t.vehicle_name ?? t.name ?? t.vehicle ?? "Rifa";
  const plate = t.plate ?? t.vehicle_plate ?? t.placa ?? "";
  const image = t.image_url ?? t.image ?? t.img ?? "";
  const status = (t.status ?? t.state ?? "").toString().toLowerCase();
  const raffleId = t.raffle_id ?? t.id_raffle ?? t.raffle ?? null;
  return { number, vehicle, plate, image, status, raffleId, raw:t };
}

function statusChip(status){
  if (!status) return `<span class="chip">Pendente</span>`;
  if (status.includes("win") || status.includes("ganh")) return `<span class="chip ok">Ganhou</span>`;
  if (status.includes("lose") || status.includes("perd")) return `<span class="chip bad">Perdeu</span>`;
  if (status.includes("paid") || status.includes("pago")) return `<span class="chip ok">Pago</span>`;
  return `<span class="chip">${esc(status)}</span>`;
}

function renderMyTickets(filterText = "") {
  const list = Array.isArray(state.myTickets) ? state.myTickets : [];
  const q = (filterText || "").trim().toLowerCase();


  const normalized = list.map(normalizeTicket).filter(t => {
    if (!q) return true;
    return (
      String(t.number).toLowerCase().includes(q) ||
      String(t.vehicle).toLowerCase().includes(q) ||
      String(t.plate).toLowerCase().includes(q) ||
      String(t.raffleId ?? "").toLowerCase().includes(q)
    );
  });

 
  const groups = {};
  for (const t of normalized) {
    const key = String(t.raffleId ?? "0");
    if (!groups[key]) {
      groups[key] = {
        raffleId: t.raffleId,
        vehicle: t.vehicle,
        plate: t.plate,
        image: t.image,
        status: t.status,
        numbers: []
      };
    }
    groups[key].numbers.push(Number(t.number));
  }

  const grouped = Object.values(groups).map(g => {
    g.numbers = g.numbers
      .filter(n => Number.isFinite(n))
      .sort((a,b) => a - b); 
    return g;
  });

  el.myTicketsCount.textContent = String(grouped.length);
  el.myTicketsList.innerHTML = "";

  if (!grouped.length){
    el.myTicketsEmpty.classList.remove("hidden");
    return;
  }
  el.myTicketsEmpty.classList.add("hidden");

  grouped.forEach((g) => {
    const card = document.createElement("div");
    card.className = "ticket-card";

    const shown = g.numbers.slice(0, 18); // mostra 18 primeiro
    const hiddenCount = Math.max(0, g.numbers.length - shown.length);

    card.innerHTML = `
      <div class="ticket-top">
        <div class="ticket-thumb">
          <img src="${esc(g.image)}" onerror="this.src=''; this.style.display='none';" />
        </div>

        <div class="ticket-info">
          <div class="ticket-title">${esc(g.vehicle)}</div>
          <div class="ticket-sub">${g.plate ? `Placa: ${esc(g.plate)}` : `ID Rifa: ${esc(g.raffleId ?? '-')}`}</div>
          <div class="ticket-sub">Cotas: <b>${g.numbers.length}</b></div>
        </div>

        <div class="chip">${statusChip(g.status)}</div>
      </div>

      <div class="ticket-bottom" style="flex-direction:column; align-items:stretch;">
        <div class="numbers-wrap">
          <div class="numbers-title tiny">Números</div>
          <div class="numbers-list">${shown.map(n => `<span class="num-pill">${n}</span>`).join("")}</div>
          ${hiddenCount > 0 ? `<button class="small-btn" data-more="${esc(g.raffleId ?? '')}">+${hiddenCount} números</button>` : ""}
        </div>

   
      </div>
    `;

   
    card.querySelector("[data-copy]")?.addEventListener("click", () => {
      const text = g.numbers.join(", ");
      if (navigator.clipboard) navigator.clipboard.writeText(text);
    });

    card.querySelector("[data-more]")?.addEventListener("click", () => {
      // expandir tudo
      const all = g.numbers.map(n => `<span class="num-pill">${n}</span>`).join("");
      const listEl = card.querySelector(".numbers-list");
      const btn = card.querySelector("[data-more]");
      if (listEl) listEl.innerHTML = all;
      if (btn) btn.remove();
    });

    el.myTicketsList.appendChild(card);
  });
}
function normalizeWinner(w){
  const vehicle = w.vehicle_name ?? w.vehicle ?? w.name ?? "Rifa";
  const plate = w.plate ?? w.vehicle_plate ?? w.placa ?? "";
  const image = w.image_url ?? w.image ?? w.img ?? "";
  const winnerName = w.winner_name ?? w.name_winner ?? w.player ?? w.nome ?? "Ganhador";
  const passport = w.passport ?? w.user_id ?? w.id ?? "-";
  const ticket = w.ticket ?? w.number ?? w.ticket_number ?? "-";
  const date = w.date ?? w.created_at ?? w.time ?? "";
  return { vehicle, plate, image, winnerName, passport, ticket, date, raw:w };
}

function renderWinners(){
  const list = Array.isArray(state.winners) ? state.winners : [];
  const mapped = list.map(normalizeWinner);

  el.winnersCount.textContent = String(mapped.length);
  el.winnersList.innerHTML = "";

  if (!mapped.length){
    el.winnersEmpty.classList.remove("hidden");
    return;
  }
  el.winnersEmpty.classList.add("hidden");

  mapped.forEach((w) => {
    const card = document.createElement("div");
    card.className = "ticket-card";


    card.innerHTML = `
      <div class="ticket-top">
        <div class="ticket-thumb">
          <img src="${esc(w.image)}" onerror="this.src=''; this.style.display='none';" />
        </div>

        <div class="ticket-info">
          <div class="ticket-title">${esc(w.vehicle)}</div>
    
          <div class="ticket-sub">
            ${esc(w.raw.name)} • Ticket #${esc(w.raw.winner_number)}
          </div>
        </div>
    

      </div>

      <div class="ticket-bottom">
        <span class="tiny">Resultado publicado</span>
      </div>
    `;

    el.winnersList.appendChild(card);
  });
}



// ==========================================================
// Loaders (simples)
// ==========================================================
function loadHomeData(){
  postNui("loadData", {}, function (data) {
    if (!data || typeof data !== "object") return;

    state.activeRaffles = Array.isArray(data.active) ? data.active : [];
    state.userData = data.user || null;

    renderHome();
  });
}

function loadMyTickets(cb){
  postNui("getMyTickets", {}, function (tickets) {
    state.myTickets = Array.isArray(tickets) ? tickets : [];
    if (typeof cb === "function") cb(state.myTickets);
  });
}

function openSettings(){
  showView("settings");

  postNui("getMyVehicles", {}, function (vehs) {
    state.myVehicles = Array.isArray(vehs) ? vehs : [];
    renderVehicles();
  });

  loadMyTickets(function () {
    if (state.view === "my_tickets") renderMyTickets(el.ticketsSearch.value);
  });


}

if (el.ticketsSearch){
  el.ticketsSearch.addEventListener("input", () => {
    renderMyTickets(el.ticketsSearch.value);
  });
}


// ==========================================================
// Events
// ==========================================================
el.btnBack.addEventListener("click", goBack);


el.btnProfile.addEventListener("click", function (e) {
  e.preventDefault();
  e.stopPropagation();
  openSettings();
});













function formatBRL(n){
  n = Number(n) || 0;
  return "R$ " + n.toLocaleString("pt-BR");
}

function openBuyModal(raffle){
  state.selectedRaffle = raffle;
  state.buyQty = 1;
  state.buying = false;

  const price = Number(raffle.price || 0);

  el.buyTitle.textContent = raffle.vehicle_name || raffle.name || "Rifa";
  el.buyImage.src = raffle.image_url || raffle.image || "";
  el.buyPrice.textContent = formatBRL(price);

  el.qtyValue.textContent = String(state.buyQty);
  el.buyTotal.textContent = formatBRL(price * state.buyQty);

  el.buyMsg.classList.add("hidden");
  el.buyMsg.textContent = "";
  el.buyMsg.classList.remove("ok", "bad");

  el.buyConfirm.disabled = false;
  el.buyConfirm.textContent = "Comprar";

  el.buyModal.classList.remove("hidden");
}

function closeBuyModal(){
  el.buyModal.classList.add("hidden");
}

function updateBuyTotal(){
  const r = state.selectedRaffle;
  if (!r) return;

  const price = Number(r.price || 0);
  el.qtyValue.textContent = String(state.buyQty);
  el.buyTotal.textContent = formatBRL(price * state.buyQty);
}

function showBuyMsg(text, ok){
  const box = document.getElementById("buyMsg");
  box.classList.remove("hidden");
  box.classList.toggle("ok", !!ok);
  box.classList.toggle("bad", !ok);
  box.style.whiteSpace = "pre-line"; 
  box.textContent = text;
}

function doBuyTickets(){
  if (state.buying) return;
  const r = state.selectedRaffle;
  if (!r) return;

  const qty = Math.max(1, Number(state.buyQty || 1));
  state.buying = true;

  el.buyConfirm.disabled = true;
  el.buyConfirm.textContent = "Comprando...";

  postNui("buyTicket", { id: r.id, quantity: qty }, function(resp){
    state.buying = false;
    el.buyConfirm.disabled = false;
    el.buyConfirm.textContent = "Comprar";

      const ok = (resp === true) || (resp && resp.success === true);
    const msg = (resp && resp.msg) ? resp.msg : (ok ? "Compra aprovada!" : "Falha na compra.");
    const nums = (resp && Array.isArray(resp.numbers)) ? resp.numbers : [];

    if (ok && nums.length) {
      nums.sort((a,b) => a-b);
      const textNums = nums.join(", ");
      showBuyMsg(`${msg}\nSeus números: ${textNums}`, true);


      navigator.clipboard.writeText(textNums);
    } else {
      showBuyMsg(msg, ok);
    }

    if (ok) {
      loadHomeData();
      loadMyTickets(function () {
        if (state.view === "my_tickets") {
          renderMyTickets(el.ticketsSearch ? el.ticketsSearch.value : "");
        }
      });
    }

  });
}



document.addEventListener("click", (e) => {
  const close = e.target.closest("[data-modal='close']");
  if (close) closeBuyModal();
});


el.qtyMinus.addEventListener("click", () => {
  state.buyQty = Math.max(1, state.buyQty - 1);
  updateBuyTotal();
});

el.qtyPlus.addEventListener("click", () => {
  state.buyQty = Math.min(999, state.buyQty + 1);
  updateBuyTotal();
});

el.buyConfirm.addEventListener("click", doBuyTickets);



document.addEventListener("click", (e) => {
  const btn = e.target.closest("[data-go]");
  if (!btn) return;

  const v = btn.getAttribute("data-go");

  if (v === "create_raffle") {
    showView("create_raffle");
  } else if (v === "my_tickets") {
    showView("my_tickets");
    renderMyTickets(el.ticketsSearch ? el.ticketsSearch.value : "");
  } else if (v === "winners") {
    showView("winners");
    loadWinners();
  } else {
    showView("placeholder");
    el.placeholderText.textContent = "Tela em breve.";
  }
});


el.btnPublish.addEventListener("click", () => {
  const v = state.selectedVehicle;
  if (!v) return;

  const payload = {
    model: v.model,
    name: v.name,
    plate: v.plate,
    image: (el.raffleImage.value || "").trim(),
    price: el.rafflePrice.value || "",
    total: el.raffleTotal.value || "",
  };

  postNui("createRaffle", payload, function (ok) {
    if (ok){
      showView("home");
      loadHomeData();
    }
  });
});

// ==========================================================
// INIT
// ==========================================================
showView("home");
loadHomeData();
