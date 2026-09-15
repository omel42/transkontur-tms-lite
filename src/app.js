import {
  STATUSES,
  NEXT_STATUS,
  STATUS_LABEL,
  money,
  shortDate,
  dateTime,
  tripMargin,
  marginPercent,
  calculateMetrics,
  filterTrips,
  createTrip,
  updateTripStatus,
  tripsToCsv
} from "./domain.js?v=5";
import { seedState } from "./seed.js?v=5";

const STORAGE_KEY = "transkontur-demo-v5";
const APP_VIEWS = new Set(["dashboard", "leads", "trips", "clients", "finance", "network"]);
const PUBLIC_SECTIONS = new Set(["", "top", "services", "control", "process", "carriers", "quick-quote"]);
const LEAD_COLUMNS = [
  { id: "new", label: "Новые" },
  { id: "contacted", label: "Уточнение" },
  { id: "quote", label: "Расчёт отправлен" },
  { id: "agreed", label: "Согласовано" }
];
const LEAD_NEXT = { new: "contacted", contacted: "quote", quote: "agreed", agreed: "agreed" };
const LEAD_LABEL = Object.fromEntries(LEAD_COLUMNS.map((item) => [item.id, item.label]));
const STATUS_TONE = { new: "gray", planned: "blue", loading: "orange", in_transit: "purple", delivered: "green", closed: "gray", issue: "red" };
const PAYMENT_LABEL = { not_invoiced: "Не выставлен", invoice: "Счёт выставлен", paid: "Оплачен", overdue: "Просрочен" };

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const clone = (value) => globalThis.structuredClone ? structuredClone(value) : JSON.parse(JSON.stringify(value));
const esc = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" }[char]));
const initials = (value = "") => value.split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join("").toUpperCase();
const round = (value, step = 1000) => Math.round((Number(value) || 0) / step) * step;
const isoNow = () => new Date().toISOString();
const dateInput = (value) => value ? new Date(value).toISOString().slice(0, 10) : "";

const dom = {
  marketing: $("#marketing-site"), workspace: $("#workspace"), rolePage: $("#role-page"), app: $("#app"),
  drawer: $("#drawer-panel"), drawerBackdrop: $("#drawer-backdrop"),
  modal: $("#modal-panel"), modalBackdrop: $("#modal-backdrop"), toast: $("#toast"),
  marketingHeader: $("#marketing-header"), marketingNav: $(".marketing-nav")
};

let state = loadState();
let ui = { view: "dashboard", query: "", tripStatus: "all", leadStatus: "all" };
let toastTimer;

function loadState() {
  try {
    const parsed = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (parsed && Array.isArray(parsed.trips) && Array.isArray(parsed.leads) && Array.isArray(parsed.clients)) return parsed;
  } catch (_) {}
  return clone(seedState);
}

function saveState() { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }
function findTrip(idOrNumber) { return state.trips.find((trip) => trip.id === idOrNumber || trip.number.toLowerCase() === String(idOrNumber || "").toLowerCase()); }
function driverFor(trip) { return state.drivers.find((item) => item.id === trip.driverId) || {}; }
function vehicleFor(trip) { return state.vehicles.find((item) => item.id === trip.vehicleId) || {}; }
function carrierFor(trip) { return state.carriers.find((item) => item.id === trip.carrierId) || {}; }
function statusBadge(status) { return `<span class="status-badge tone-${STATUS_TONE[status] || "gray"}">${esc(STATUS_LABEL[status] || status)}</span>`; }
function pageHead(title, subtitle, actions = "") { return `<div class="page-heading"><div><h1>${title}</h1><p>${subtitle}</p></div><div class="page-actions">${actions}</div></div>`; }
function statCard(label, value, note, icon, dark = false) { return `<article class="stat-card${dark ? " stat-card--dark" : ""}"><div class="stat-top"><span>${label}</span><i class="stat-icon">${icon}</i></div><strong>${value}</strong><small>${note}</small></article>`; }
function shortTime(value) { return value ? new Intl.DateTimeFormat("ru-RU", { hour: "2-digit", minute: "2-digit" }).format(new Date(value)) : "—"; }

function showToast(message) {
  clearTimeout(toastTimer);
  dom.toast.textContent = message;
  dom.toast.classList.add("show");
  toastTimer = setTimeout(() => dom.toast.classList.remove("show"), 2600);
}

function closeOverlays() {
  dom.drawer.hidden = true; dom.drawerBackdrop.hidden = true;
  dom.modal.hidden = true; dom.modalBackdrop.hidden = true;
  document.body.classList.remove("modal-open");
}

function showModal(content) {
  dom.modal.innerHTML = content; dom.modal.hidden = false; dom.modalBackdrop.hidden = false;
  document.body.classList.add("modal-open");
}

function showDrawer(content) {
  dom.drawer.innerHTML = content; dom.drawer.hidden = false; dom.drawerBackdrop.hidden = false;
  document.body.classList.add("modal-open");
}

function route() {
  closeOverlays();
  const raw = location.hash.replace(/^#/, "");
  const [root, id] = raw.split("/");
  if (root === "office") {
    ui.view = APP_VIEWS.has(id) ? id : "dashboard";
    showSurface("workspace"); renderApp(); window.scrollTo(0, 0); return;
  }
  if (["track", "driver", "carrier"].includes(root)) {
    showSurface("role"); renderRole(root, id); window.scrollTo(0, 0); return;
  }
  showSurface("marketing");
  if (!PUBLIC_SECTIONS.has(root)) location.hash = "#top";
  requestAnimationFrame(initReveal);
}

function showSurface(surface) {
  dom.marketing.hidden = surface !== "marketing";
  dom.workspace.hidden = surface !== "workspace";
  dom.rolePage.hidden = surface !== "role";
}

function renderApp() {
  const renderer = { dashboard: renderDashboard, leads: renderLeads, trips: renderTrips, clients: renderClients, finance: renderFinance, network: renderNetwork }[ui.view];
  dom.app.innerHTML = renderer();
  $$("[data-view]").forEach((button) => button.classList.toggle("active", button.dataset.view === ui.view));
  const openLeads = state.leads.filter((lead) => lead.status !== "agreed").length;
  const count = $("#lead-count"); if (count) count.textContent = openLeads;
  const search = $("#global-search"); if (search) search.value = ui.query;
}

function renderDashboard() {
  const metrics = calculateMetrics(state.trips);
  const activeTrips = state.trips.filter((trip) => ["planned", "loading", "in_transit", "issue"].includes(trip.status));
  const potentialMargin = state.leads.reduce((sum, lead) => sum + (Number(lead.clientRate) - Number(lead.carrierRate)), 0);
  const needsDocs = state.trips.filter((trip) => !trip.docs?.waybill && ["loading", "in_transit", "delivered"].includes(trip.status));
  const agreed = state.leads.filter((lead) => lead.status === "agreed");
  const alerts = [
    ...agreed.map((lead) => ({ icon: "↗", title: `${lead.number}: назначить машину`, sub: `${lead.from} → ${lead.to}`, type: "lead", id: lead.id })),
    ...needsDocs.map((trip) => ({ icon: "▣", title: `${trip.number}: нет транспортной накладной`, sub: `${trip.client} · ${trip.from} → ${trip.to}`, type: "trip", id: trip.id })),
    ...state.trips.filter((trip) => trip.paymentStatus === "overdue").map((trip) => ({ icon: "₽", title: `${trip.number}: просрочена оплата`, sub: `${trip.client} · ${money(trip.price)}`, type: "trip", id: trip.id }))
  ].slice(0, 5);
  const maxLead = Math.max(1, ...LEAD_COLUMNS.map((col) => state.leads.filter((lead) => lead.status === col.id).length));
  return `<div class="app-page">
    ${pageHead("Добрый день, Алексей", "Операционная картина на сегодня — без лишних отчётов.", `<button class="subtle-button" data-action="export-csv">↓ <span class="mobile-hide">Выгрузить CSV</span></button><button class="button button--small button--dark" data-action="new-lead">＋ Новая заявка</button>`)}
    <section class="stats-grid">
      ${statCard("Активные рейсы", metrics.active, `${activeTrips.filter((t) => t.status === "in_transit").length} сейчас в пути`, "▰", true)}
      ${statCard("Новые заявки", state.leads.filter((l) => l.status === "new").length, `${agreed.length} ждут назначения`, "↗")}
      ${statCard("Потенциал маржи", money(potentialMargin), "по открытым заявкам", "₽")}
      ${statCard("Требуют внимания", alerts.length, `${metrics.docsIssues} вопроса по документам`, "!")}
    </section>
    <div class="dashboard-grid">
      <div class="stack">
        <section class="panel"><div class="panel-head"><div><h2>Рейсы в работе</h2><p>Главное по текущим перевозкам</p></div><button class="panel-link" data-view="trips">Все рейсы →</button></div>${tripTable(activeTrips.slice(0, 5))}</section>
        <section class="panel"><div class="panel-head"><div><h2>Воронка заявок</h2><p>От первого контакта до назначения</p></div><button class="panel-link" data-view="leads">Открыть доску →</button></div><div class="funnel">${LEAD_COLUMNS.map((col) => { const count = state.leads.filter((l) => l.status === col.id).length; return `<div class="funnel-row"><span>${col.label}</span><div class="funnel-bar"><i style="width:${Math.max(8, count / maxLead * 100)}%"></i></div><b>${count}</b></div>`; }).join("")}</div></section>
      </div>
      <aside class="stack">
        <section class="panel"><div class="panel-head"><div><h2>Нужна реакция</h2><p>${alerts.length} пунктов на сегодня</p></div></div><div class="attention-list">${alerts.length ? alerts.map((a) => `<div class="attention-item"><span>${a.icon}</span><div><strong>${esc(a.title)}</strong><small>${esc(a.sub)}</small></div><button data-open-${a.type}="${a.id}" aria-label="Открыть">→</button></div>`).join("") : `<div class="empty-state"><span>✓</span><h3>Всё спокойно</h3><p>Критичных задач нет.</p></div>`}</div></section>
        <section class="panel"><div class="panel-head"><div><h2>Ближайшие события</h2><p>Погрузки и выгрузки</p></div></div><div class="agenda">${activeTrips.sort((a,b) => new Date(a.eta)-new Date(b.eta)).slice(0,4).map((trip) => `<div class="agenda-item"><time>${shortTime(trip.eta)}</time><div><strong>${esc(trip.number)} · ${esc(trip.to)}</strong><small>${esc(trip.status === "planned" ? "Плановая погрузка" : STATUS_LABEL[trip.status])}</small></div></div>`).join("")}</div></section>
      </aside>
    </div>
  </div>`;
}

function tripTable(trips) {
  if (!trips.length) return `<div class="empty-state"><span>⌕</span><h3>Ничего не найдено</h3><p>Измените фильтр или поисковый запрос.</p></div>`;
  return `<div class="table-wrap"><table class="data-table"><thead><tr><th>Рейс</th><th>Маршрут</th><th>Клиент</th><th>Экипаж</th><th>ETA</th><th>Статус</th></tr></thead><tbody>${trips.map((trip) => { const driver = driverFor(trip); const vehicle = vehicleFor(trip); return `<tr data-open-trip="${trip.id}"><td><span class="table-id">${esc(trip.number)}</span></td><td><div class="route-cell"><strong>${esc(trip.from)} → ${esc(trip.to)}</strong><span>${esc(trip.cargo)} · ${trip.weight || "—"} т</span></div></td><td><div class="person-cell"><span class="avatar">${initials(trip.client)}</span><div><strong>${esc(trip.client)}</strong><small>${esc(trip.contact || "Контакт не указан")}</small></div></div></td><td><div class="route-cell"><strong>${esc(driver.name || "Не назначен")}</strong><span>${esc(vehicle.plate || "Машина не назначена")}</span></div></td><td>${shortDate(trip.eta)}<br><small>${shortTime(trip.eta)}</small></td><td>${statusBadge(trip.status)}</td></tr>`; }).join("")}</tbody></table></div>`;
}

function renderLeads() {
  const leads = state.leads.filter((lead) => !ui.query || [lead.number, lead.company, lead.from, lead.to, lead.cargo].join(" ").toLowerCase().includes(ui.query.toLowerCase()));
  return `<div class="app-page">${pageHead("Заявки", "Рабочая доска: от входящего звонка до назначенной машины.", `<button class="button button--small button--dark" data-action="new-lead">＋ Новая заявка</button>`)}<section class="kanban">${LEAD_COLUMNS.map((column) => { const items = leads.filter((lead) => lead.status === column.id); return `<div class="kanban-column"><div class="kanban-head">${column.label}<span>${items.length}</span></div>${items.map(leadCard).join("")}</div>`; }).join("")}</section></div>`;
}

function leadCard(lead) {
  const margin = Number(lead.clientRate || 0) - Number(lead.carrierRate || 0);
  return `<article class="lead-card" data-open-lead="${lead.id}"><div class="lead-card-top"><span>${esc(lead.number)}</span><b class="tag tone-${lead.source === "Сайт" ? "acid" : "gray"}">${esc(lead.source)}</b></div><div><h3>${esc(lead.company)}</h3><p>${esc(lead.contact)} · ${esc(lead.phone)}</p></div><div class="lead-card-meta"><span>${esc(lead.from)} → ${esc(lead.to)}</span><b>${lead.weight || "—"} т</b></div><div class="lead-card-foot"><div><small>Ставка клиенту</small><strong>${money(lead.clientRate)}</strong></div><div><small>Маржа</small><strong class="money-positive">${money(margin)}</strong></div></div></article>`;
}

function renderTrips() {
  const filtered = filterTrips(state.trips, { query: ui.query, status: ui.tripStatus });
  const options = [{ id: "all", label: "Все" }, ...STATUSES.filter((s) => s.id !== "issue")];
  return `<div class="app-page">${pageHead("Рейсы", `${filtered.length} перевозок в выбранном представлении.`, `<button class="subtle-button" data-action="export-csv">↓ CSV</button>`)}<div class="filters" style="margin-bottom:14px">${options.map((item) => `<button class="filter-button ${ui.tripStatus === item.id ? "active" : ""}" data-trip-filter="${item.id}">${item.label}</button>`).join("")}</div><section class="panel">${tripTable(filtered)}</section></div>`;
}

function renderClients() {
  const clients = state.clients.filter((client) => !ui.query || [client.name, client.contact, client.phone, client.lastRoute].join(" ").toLowerCase().includes(ui.query.toLowerCase()));
  return `<div class="app-page">${pageHead("Клиенты", "История сотрудничества, выручка и дебиторка в одном месте.")}<section class="card-grid">${clients.map((client) => `<article class="entity-card"><div class="entity-head"><span class="avatar">${initials(client.name)}</span><div><h3>${esc(client.name)}</h3><p>${esc(client.contact)} · ${esc(client.phone)}</p></div></div><div class="entity-meta"><div><small>Перевозок</small><strong>${client.orders}</strong></div><div><small>Выручка</small><strong>${money(client.revenue)}</strong></div><div><small>Последний маршрут</small><strong>${esc(client.lastRoute)}</strong></div><div><small>Дебиторка</small><strong class="${client.debt ? "" : "money-positive"}">${client.debt ? money(client.debt) : "Нет"}</strong></div></div></article>`).join("")}</section></div>`;
}

function renderFinance() {
  const totalRevenue = state.trips.reduce((sum, trip) => sum + Number(trip.price || 0), 0);
  const totalMargin = state.trips.reduce((sum, trip) => sum + tripMargin(trip), 0);
  const debt = state.trips.filter((trip) => ["invoice", "overdue"].includes(trip.paymentStatus)).reduce((sum, trip) => sum + Number(trip.price || 0), 0);
  const avg = totalRevenue ? Math.round(totalMargin / totalRevenue * 100) : 0;
  return `<div class="app-page">${pageHead("Финансы", "Управленческая экономика рейсов. Не заменяет бухгалтерский учёт.", `<button class="subtle-button" data-action="export-csv">↓ Выгрузить</button>`)}<section class="stats-grid">${statCard("Выручка рейсов", money(totalRevenue), "по текущей демо-выборке", "₽", true)}${statCard("Валовая маржа", money(totalMargin), `${avg}% от выручки`, "↗")}${statCard("К получению", money(debt), "счета и просрочка", "◷")}${statCard("Просрочено", money(state.trips.filter((t) => t.paymentStatus === "overdue").reduce((s,t) => s+t.price,0)), "требует контакта с клиентом", "!")}</section><div class="finance-grid"><section class="panel"><div class="panel-head"><div><h2>Экономика по рейсам</h2><p>Ставка, себестоимость и маржа</p></div></div><div class="table-wrap"><table class="data-table"><thead><tr><th>Рейс</th><th>Клиент</th><th>Выручка</th><th>Себестоимость</th><th>Маржа</th><th>Оплата</th></tr></thead><tbody>${state.trips.map((trip) => `<tr data-open-trip="${trip.id}"><td><b>${trip.number}</b></td><td>${esc(trip.client)}</td><td>${money(trip.price)}</td><td>${money(trip.actualCost || trip.plannedCost)}</td><td class="money-positive">${money(tripMargin(trip))} · ${marginPercent(trip)}%</td><td><span class="tag tone-${trip.paymentStatus === "paid" ? "green" : trip.paymentStatus === "overdue" ? "red" : "gray"}">${PAYMENT_LABEL[trip.paymentStatus] || "—"}</span></td></tr>`).join("")}</tbody></table></div></section><section class="panel"><div class="panel-head"><div><h2>Маржинальность</h2><p>Доля маржи в ставке</p></div></div><div class="margin-list">${state.trips.map((trip) => `<div class="margin-row"><div class="margin-row-head"><span>${trip.number} · ${esc(trip.client)}</span><strong>${marginPercent(trip)}%</strong></div><div class="margin-track"><i style="width:${Math.max(0, Math.min(100, marginPercent(trip)))}%"></i></div></div>`).join("")}</div></section></div></div>`;
}

function renderNetwork() {
  const carriers = state.carriers.filter((item) => !ui.query || [item.name, item.inn, item.type].join(" ").toLowerCase().includes(ui.query.toLowerCase()));
  return `<div class="app-page">${pageHead("Перевозчики", "Собственная рабочая база: специализация, надёжность и актуальность документов.")}<section class="card-grid">${carriers.map((item) => `<article class="entity-card"><div class="entity-head"><span class="avatar">${initials(item.name)}</span><div><h3>${esc(item.name)}</h3><p>ИНН ${esc(item.inn)} · ${esc(item.phone)}</p></div></div><div class="entity-meta"><div><small>Специализация</small><strong>${esc(item.type)}</strong></div><div><small>Рейтинг</small><strong>★ ${item.rating} · ${item.completed} рейсов</strong></div><div><small>В срок</small><strong>${item.onTime}%</strong></div><div><small>Документы до</small><strong>${shortDate(item.docsUntil)}</strong></div></div></article>`).join("")}</section></div>`;
}

function openTripDrawer(id) {
  const trip = findTrip(id); if (!trip) return;
  const driver = driverFor(trip), vehicle = vehicleFor(trip), carrier = carrierFor(trip);
  const flow = ["planned", "loading", "in_transit", "delivered", "closed"];
  const current = flow.indexOf(trip.status);
  const docs = [
    ["request", "Заявка на перевозку"], ["waybill", "Транспортная накладная"],
    ["closing", "Акт и закрывающие"], ["invoice", "Счёт клиенту"]
  ];
  showDrawer(`<header class="drawer-head"><div><small>Карточка перевозки</small><h2>${esc(trip.number)} · ${esc(trip.client)}</h2></div><button class="close-button" data-action="close-overlay">×</button></header>
    <div class="drawer-body">
      <section class="drawer-route"><h3>${esc(trip.from)} → ${esc(trip.to)}</h3><p>${esc(trip.cargo)} · ${trip.weight || "—"} т · ${trip.distance || "—"} км</p><div class="drawer-route-meta"><div><small>ETA</small><strong>${dateTime(trip.eta)}</strong></div><div><small>Водитель</small><strong>${esc(driver.name || "Не назначен")}</strong></div><div><small>Машина</small><strong>${esc(vehicle.plate || "Не назначена")}</strong></div></div></section>
      <section class="drawer-section"><div class="drawer-section-head"><h3>Статус рейса</h3>${statusBadge(trip.status)}</div><div class="status-steps">${flow.map((status, index) => `<span class="status-step ${index < current ? "done" : index === current ? "current" : ""}">${STATUS_LABEL[status]}</span>`).join("")}</div></section>
      <section class="drawer-section"><div class="drawer-section-head"><h3>Участники и экономика</h3><span class="tag tone-green">Маржа ${marginPercent(trip)}%</span></div><div class="detail-grid"><div><small>Клиент</small><strong>${esc(trip.client)} · ${esc(trip.contact)}</strong></div><div><small>Телефон</small><strong>${esc(trip.phone)}</strong></div><div><small>Перевозчик</small><strong>${esc(carrier.name || "Не назначен")}</strong></div><div><small>Стоимость клиенту</small><strong>${money(trip.price)}</strong></div><div><small>Себестоимость</small><strong>${money(trip.actualCost || trip.plannedCost)}</strong></div><div><small>Валовая маржа</small><strong class="money-positive">${money(tripMargin(trip))}</strong></div></div></section>
      <section class="drawer-section"><div class="drawer-section-head"><h3>Документы</h3><span class="tag tone-gray">${docs.filter(([key]) => trip.docs?.[key]).length} / ${docs.length}</span></div><div class="document-list">${docs.map(([key,label]) => `<label class="document-row"><input type="checkbox" data-doc-trip="${trip.id}" data-doc-key="${key}" ${trip.docs?.[key] ? "checked" : ""}><span>${label}</span><small>${trip.docs?.[key] ? "Получено" : "Ожидаем"}</small></label>`).join("")}</div></section>
      <section class="drawer-section"><div class="drawer-section-head"><h3>Хронология</h3></div><div class="event-list">${[...(trip.events || [])].reverse().map((event) => `<div class="event-item"><time>${dateTime(event.at)}</time><div><strong>${esc(event.note)}</strong><small>${esc(STATUS_LABEL[event.status] || event.status)}</small></div></div>`).join("")}</div></section>
    </div>
    <footer class="drawer-actions">${NEXT_STATUS[trip.status] && NEXT_STATUS[trip.status] !== trip.status ? `<button class="button button--dark" data-advance-trip="${trip.id}">Следующий этап: ${STATUS_LABEL[NEXT_STATUS[trip.status]]}</button>` : ""}<button class="subtle-button" data-copy-role="track" data-trip-number="${trip.number}">Ссылка клиенту</button><button class="subtle-button" data-copy-role="driver" data-trip-number="${trip.number}">Ссылка водителю</button></footer>`);
}

function openLeadDrawer(id) {
  const lead = state.leads.find((item) => item.id === id); if (!lead) return;
  const margin = Number(lead.clientRate || 0) - Number(lead.carrierRate || 0);
  showDrawer(`<header class="drawer-head"><div><small>${esc(LEAD_LABEL[lead.status])}</small><h2>${esc(lead.number)} · ${esc(lead.company)}</h2></div><button class="close-button" data-action="close-overlay">×</button></header><div class="drawer-body"><section class="drawer-route"><h3>${esc(lead.from)} → ${esc(lead.to)}</h3><p>${esc(lead.cargo)} · ${lead.weight || "—"} т · погрузка ${shortDate(lead.pickupAt)}</p><div class="drawer-route-meta"><div><small>Клиенту</small><strong>${money(lead.clientRate)}</strong></div><div><small>Перевозчику</small><strong>${money(lead.carrierRate)}</strong></div><div><small>Плановая маржа</small><strong>${money(margin)}</strong></div></div></section><section class="drawer-section"><div class="drawer-section-head"><h3>Контакт</h3><span class="tag tone-${lead.source === "Сайт" ? "acid" : "gray"}">${esc(lead.source)}</span></div><div class="detail-grid"><div><small>Контактное лицо</small><strong>${esc(lead.contact || "Не указано")}</strong></div><div><small>Телефон</small><strong>${esc(lead.phone)}</strong></div><div><small>Следующее действие</small><strong>${esc(lead.nextAction)}</strong></div><div><small>Создана</small><strong>${dateTime(lead.createdAt)}</strong></div></div></section><section class="drawer-section"><div class="drawer-section-head"><h3>Нюансы</h3></div><p style="margin:0;color:#67747b;font-size:12px;line-height:1.7">${esc(lead.note || "Комментариев пока нет.")}</p></section></div><footer class="drawer-actions">${lead.status !== "agreed" ? `<button class="button button--dark" data-advance-lead="${lead.id}">Перевести: ${LEAD_LABEL[LEAD_NEXT[lead.status]]}</button>` : `<button class="button button--dark" data-convert-lead="${lead.id}">Создать рейс</button>`}<a class="subtle-button" href="tel:${esc(lead.phone)}">Позвонить</a></footer>`);
}

function renderRole(role, id) {
  if (role === "track" && !id) { dom.rolePage.innerHTML = renderTrackSearch(); return; }
  const trip = findTrip(id || "TK-24031");
  if (!trip) { dom.rolePage.innerHTML = renderTrackSearch("Рейс не найден. Для демо попробуйте TK-24031."); return; }
  dom.rolePage.innerHTML = role === "driver" ? renderDriver(trip) : renderGuestPortal(trip, role);
}

function roleHeader(roleLabel) {
  return `<header class="role-topbar"><a class="brand brand--light" href="#top"><img src="./assets/logo-mark.svg" width="42" height="42" alt=""><span><strong>ТрансКонтур</strong><small>${roleLabel}</small></span></a><div class="role-topbar-actions"><a class="role-back" href="#top">← На сайт</a><a class="button button--small button--ghost" href="#office">Рабочее демо</a></div></header>`;
}

function renderTrackSearch(message = "Введите номер из заявки или сообщения логиста.") {
  return `<div class="role-shell">${roleHeader("контроль перевозки")}<main class="role-main"><section class="role-search"><span class="role-label">Отследить груз</span><h1>Где мой рейс?</h1><p>${message}</p><form id="track-form"><input name="number" placeholder="Например, TK-24031" required><button class="button button--acid" type="submit">Показать →</button></form></section></main></div>`;
}

function renderGuestPortal(trip, role) {
  const isCarrier = role === "carrier", driver = driverFor(trip), vehicle = vehicleFor(trip);
  const flow = ["planned", "loading", "in_transit", "delivered", "closed"];
  const current = Math.max(0, flow.indexOf(trip.status));
  return `<div class="role-shell">${roleHeader(isCarrier ? "кабинет перевозчика" : "контроль перевозки")}<main class="role-main"><span class="role-label">${isCarrier ? "Кабинет перевозчика" : `Рейс ${esc(trip.number)}`}</span><div class="role-title-row"><div><h1>${esc(trip.from)} → ${esc(trip.to)}</h1><p>${esc(trip.cargo)} · ${trip.weight} т · ${esc(vehicle.type || "Тип машины уточняется")}</p></div><span class="role-status">${esc(STATUS_LABEL[trip.status])}</span></div><div class="tracking-grid"><section class="role-card tracking-map"><div class="tracking-map-card"><small>Расчётное прибытие</small><strong>${dateTime(trip.eta)}</strong></div><span class="map-city map-city--a"><i></i>${esc(trip.from)}</span><span class="map-city map-city--b"><i></i>${esc(trip.to)}</span><span class="map-road"></span><span class="map-truck">▰</span></section><aside class="tracking-side"><section class="role-card tracking-info"><small>${isCarrier ? "Ставка перевозчика" : "Стоимость перевозки"}</small><strong>${money(isCarrier ? (trip.actualCost || trip.plannedCost) : trip.price)}</strong><div class="tracking-info-row"><span>Водитель</span><b>${esc(driver.name || "Назначается")}</b></div><div class="tracking-info-row"><span>Машина</span><b>${esc(vehicle.plate || "Назначается")}</b></div><div class="tracking-info-row"><span>Статус документов</span><b>${trip.docs?.waybill ? "ТрН получена" : "Ожидаем ТрН"}</b></div><div class="tracking-info-row"><span>${isCarrier ? "Условия" : "Связь"}</span><b>${isCarrier ? "После оригиналов" : "Через логиста"}</b></div></section><section class="role-card tracking-info"><small>Следующее действие</small><strong style="font-size:17px">${trip.status === "in_transit" ? `Прибытие в ${esc(trip.to)}` : trip.status === "loading" ? "Завершить погрузку" : trip.status === "planned" ? "Прибыть на погрузку" : "Передать документы"}</strong><p style="margin:0;color:#768187;font-size:10px">${esc(trip.comment || "Логист сообщит детали при изменении статуса.")}</p></section></aside><section class="role-card role-timeline"><h2>Ход перевозки</h2><div class="role-progress">${flow.map((status,index) => `<span class="role-progress-item ${index < current ? "done" : index === current ? "current" : ""}">${STATUS_LABEL[status]}</span>`).join("")}</div></section></div></main></div>`;
}

function renderDriver(trip) {
  const driver = driverFor(trip), vehicle = vehicleFor(trip);
  const next = { planned: ["Прибыть на погрузку", "Я на погрузке"], loading: ["Завершить погрузку", "Выехал"], in_transit: ["Доставить груз", "Я на выгрузке"], issue: ["Проблема передана логисту", "Продолжить рейс"], delivered: ["Передать документы", "Документы переданы"] }[trip.status] || ["Рейс завершён", "Готово"];
  return `<main class="driver-shell"><header class="driver-head"><div class="driver-head-row"><a class="brand brand--light" href="#top"><img src="./assets/logo-mark.svg" alt=""><span><strong>ТрансКонтур</strong><small>для водителя</small></span></a><span class="status-pill status-pill--moving">${STATUS_LABEL[trip.status]}</span></div><h1>${esc(trip.number)}</h1><p>${esc(driver.name || "Водитель")} · ${esc(vehicle.plate || "Машина не назначена")}</p></header><section class="driver-next"><small>Следующий шаг</small><h2>${next[0]}</h2><p>${esc(trip.comment || "Следуйте информации в карточке рейса.")}</p>${NEXT_STATUS[trip.status] && NEXT_STATUS[trip.status] !== trip.status ? `<button class="button button--acid button--wide" data-driver-advance="${trip.id}">${next[1]} →</button>` : ""}</section><section class="driver-card"><h3>Маршрут и контакты</h3><div class="driver-address"><span>А</span><div><strong>${esc(trip.from)}</strong><small>Погрузка · ${dateTime(trip.pickupAt)}</small></div><a href="tel:${esc(trip.phone)}">Позвонить</a></div><div class="driver-address"><span>Б</span><div><strong>${esc(trip.to)}</strong><small>Выгрузка · ${dateTime(trip.deliveryAt)}</small></div><a href="#">Маршрут</a></div></section><section class="driver-card"><h3>Груз</h3><div class="detail-grid"><div><small>Наименование</small><strong>${esc(trip.cargo)}</strong></div><div><small>Вес</small><strong>${trip.weight} т</strong></div></div></section><section class="driver-card"><h3>Быстрые действия</h3><div class="driver-actions"><button data-driver-photo="${trip.id}">▣ Фото документа</button><button data-driver-issue="${trip.id}">! Сообщить проблему</button></div></section><section class="driver-card"><h3>Контрольные точки</h3>${(trip.checkpoints || []).map((point) => `<div class="driver-address"><span>${point.done ? "✓" : "○"}</span><div><strong>${esc(point.city)}</strong><small>${esc(point.label)} · ${dateTime(point.at)}</small></div></div>`).join("") || `<p style="color:#849095;font-size:10px">Точки маршрута уточняются.</p>`}</section></main>`;
}

function newLeadModal() {
  const tomorrow = new Date(Date.now() + 86400000).toISOString().slice(0,10);
  showModal(`<header class="modal-head"><div><h2>Новая заявка</h2><p>Можно заполнить во время разговора с клиентом.</p></div><button class="close-button" data-action="close-overlay">×</button></header><form class="modal-form" id="new-lead-form"><div class="form-grid form-grid--2"><label><span>Компания</span><input name="company" required placeholder="Название клиента"></label><label><span>Контакт</span><input name="contact" placeholder="Имя"></label><label><span>Телефон</span><input name="phone" required placeholder="+7 900 000-00-00"></label><label><span>Дата погрузки</span><input name="pickup" type="date" value="${tomorrow}"></label><label><span>Откуда</span><input name="from" required placeholder="Город"></label><label><span>Куда</span><input name="to" required placeholder="Город"></label><label><span>Груз</span><input name="cargo" required placeholder="Что везём"></label><label><span>Вес, т</span><input name="weight" type="number" step="0.1" placeholder="20"></label><label><span>Ставка клиенту</span><input name="clientRate" type="number" placeholder="150000"></label><label><span>Ставка перевозчика</span><input name="carrierRate" type="number" placeholder="110000"></label></div><label><span>Нюансы</span><textarea name="note" rows="3" placeholder="Тип загрузки, температура, пропуск…"></textarea></label><button class="button button--dark button--wide" type="submit">Сохранить заявку →</button></form>`);
}

function addLeadFromForm(form, source = "Телефон") {
  const data = new FormData(form);
  const next = Math.max(1000, ...state.leads.map((lead) => Number(lead.number.replace(/\D/g,"")) || 0)) + 1;
  const from = String(data.get("from") || "").trim(), to = String(data.get("to") || "").trim();
  const clientRate = Number(data.get("clientRate") || 0);
  const carrierRate = Number(data.get("carrierRate") || (clientRate ? round(clientRate * .76) : 0));
  const lead = { id: `lead-${Date.now()}`, number: `Л-${next}`, company: String(data.get("company") || data.get("name") || "Новый клиент").trim(), contact: String(data.get("contact") || data.get("name") || "").trim(), phone: String(data.get("phone") || "").trim(), from, to, cargo: String(data.get("cargo") || "Груз уточняется").trim(), weight: Number(data.get("weight") || 0), pickupAt: data.get("pickup") ? new Date(`${data.get("pickup")}T09:00:00`).toISOString() : isoNow(), status: "new", source, clientRate, carrierRate, nextAction: "Связаться и уточнить условия", createdAt: isoNow(), note: String(data.get("note") || "Заявка создана через форму.").trim() };
  state.leads.unshift(lead); saveState(); return lead;
}

function submitQuote(form) {
  const lead = addLeadFromForm(form, "Сайт");
  showModal(`<div class="modal-success"><span class="success-mark">✓</span><h2>Заявка ${lead.number} создана</h2><p>${esc(lead.from)} → ${esc(lead.to)}. В реальном сервисе логист получил бы уведомление и связался с клиентом. В демо заявка уже лежит в рабочем кабинете.</p><a class="button button--dark button--wide" href="#office/leads">Посмотреть в кабинете →</a></div>`);
}

function convertLead(id) {
  const lead = state.leads.find((item) => item.id === id); if (!lead) return;
  let client = state.clients.find((item) => item.name.toLowerCase() === lead.company.toLowerCase());
  if (!client) { client = { id: `c-${Date.now()}`, name: lead.company, contact: lead.contact, phone: lead.phone, email: "", orders: 1, revenue: lead.clientRate, debt: 0, lastRoute: `${lead.from} → ${lead.to}`, status: "active" }; state.clients.push(client); }
  const trip = createTrip({ client: lead.company, contact: lead.contact, phone: lead.phone, from: lead.from, to: lead.to, cargo: lead.cargo, weight: lead.weight, pickupAt: lead.pickupAt, deliveryAt: new Date(new Date(lead.pickupAt).getTime()+86400000).toISOString(), price: lead.clientRate, plannedCost: lead.carrierRate, comment: lead.note }, state);
  trip.number = `TK-${24000 + state.trips.length + 1}`; trip.clientId = client.id; trip.distance = 0; trip.eta = trip.deliveryAt; trip.paymentStatus = "not_invoiced"; trip.docs.invoice = false;
  state.trips.unshift(trip); state.leads = state.leads.filter((item) => item.id !== id); saveState(); closeOverlays(); location.hash = `#office/trips`; setTimeout(() => openTripDrawer(trip.id), 120); showToast(`Рейс ${trip.number} создан`);
}

async function copyRoleLink(role, number) {
  const url = `${location.origin}${location.pathname}#${role}/${number}`;
  try { await navigator.clipboard.writeText(url); showToast("Ссылка скопирована"); }
  catch (_) { window.prompt("Скопируйте ссылку", url); }
}

function exportCsv() {
  const blob = new Blob(["\uFEFF" + tripsToCsv(state.trips)], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob), link = document.createElement("a");
  link.href = url; link.download = "transkontur-trips.csv"; link.click(); URL.revokeObjectURL(url); showToast("CSV сформирован");
}

function initReveal() {
  const items = $$(".reveal:not(.is-visible)");
  if (!("IntersectionObserver" in window)) { items.forEach((item) => item.classList.add("is-visible")); return; }
  const observer = new IntersectionObserver((entries) => entries.forEach((entry) => { if (entry.isIntersecting) { entry.target.classList.add("is-visible"); observer.unobserve(entry.target); } }), { threshold: .12 });
  items.forEach((item) => observer.observe(item));
}

document.addEventListener("click", (event) => {
  const target = event.target.closest("[data-action],[data-view],[data-open-trip],[data-open-lead],[data-trip-filter],[data-advance-trip],[data-advance-lead],[data-convert-lead],[data-copy-role],[data-driver-advance],[data-driver-photo],[data-driver-issue]");
  if (!target) return;
  if (target.dataset.view) { location.hash = `#office/${target.dataset.view}`; dom.workspace.classList.remove("menu-open"); return; }
  if (target.dataset.openTrip) { openTripDrawer(target.dataset.openTrip); return; }
  if (target.dataset.openLead) { openLeadDrawer(target.dataset.openLead); return; }
  if (target.dataset.tripFilter) { ui.tripStatus = target.dataset.tripFilter; renderApp(); return; }
  if (target.dataset.advanceTrip) { const index = state.trips.findIndex((t) => t.id === target.dataset.advanceTrip); if (index >= 0) { state.trips[index] = updateTripStatus(state.trips[index], NEXT_STATUS[state.trips[index].status]); saveState(); renderApp(); openTripDrawer(state.trips[index].id); showToast("Статус рейса обновлён"); } return; }
  if (target.dataset.advanceLead) { const lead = state.leads.find((l) => l.id === target.dataset.advanceLead); if (lead) { lead.status = LEAD_NEXT[lead.status]; lead.nextAction = lead.status === "agreed" ? "Назначить машину" : "Продолжить работу по заявке"; saveState(); renderApp(); openLeadDrawer(lead.id); } return; }
  if (target.dataset.convertLead) { convertLead(target.dataset.convertLead); return; }
  if (target.dataset.copyRole) { copyRoleLink(target.dataset.copyRole, target.dataset.tripNumber); return; }
  if (target.dataset.driverAdvance) { const index = state.trips.findIndex((t) => t.id === target.dataset.driverAdvance); if (index >= 0) { state.trips[index] = updateTripStatus(state.trips[index], NEXT_STATUS[state.trips[index].status]); saveState(); renderRole("driver", state.trips[index].number); showToast("Статус отправлен логисту"); } return; }
  if (target.dataset.driverPhoto) { const trip = findTrip(target.dataset.driverPhoto); if (trip) { trip.docs.waybill = true; trip.events.push({ at: isoNow(), status: trip.status, note: "Водитель загрузил фото транспортной накладной" }); saveState(); showToast("Фото документа добавлено в демо"); } return; }
  if (target.dataset.driverIssue) { const trip = findTrip(target.dataset.driverIssue); if (trip) { trip.status = "issue"; trip.events.push({ at: isoNow(), status: "issue", note: "Водитель сообщил о проблеме" }); saveState(); renderRole("driver", trip.number); showToast("Логист получил сигнал о проблеме"); } return; }
  const action = target.dataset.action;
  if (action === "close-overlay") closeOverlays();
  if (action === "new-lead") newLeadModal();
  if (action === "export-csv") exportCsv();
  if (action === "toggle-app-menu") dom.workspace.classList.toggle("menu-open");
  if (action === "toggle-marketing-menu") { dom.marketingNav.classList.toggle("open"); target.setAttribute("aria-expanded", String(dom.marketingNav.classList.contains("open"))); }
  if (action === "reset-demo") { if (confirm("Вернуть исходные демо-данные?")) { state = clone(seedState); saveState(); renderApp(); showToast("Демо-данные восстановлены"); } }
});

document.addEventListener("change", (event) => {
  const checkbox = event.target.closest("[data-doc-trip]"); if (!checkbox) return;
  const trip = findTrip(checkbox.dataset.docTrip); if (!trip) return;
  trip.docs[checkbox.dataset.docKey] = checkbox.checked; trip.events.push({ at: isoNow(), status: trip.status, note: `${checkbox.checked ? "Документ получен" : "Документ отмечен как отсутствующий"}: ${checkbox.closest("label").querySelector("span").textContent}` }); saveState(); showToast("Документы обновлены");
});

document.addEventListener("submit", (event) => {
  event.preventDefault();
  if (event.target.id === "hero-quote-form" || event.target.id === "final-quote-form") { submitQuote(event.target); return; }
  if (event.target.id === "new-lead-form") { const lead = addLeadFromForm(event.target); closeOverlays(); location.hash = "#office/leads"; setTimeout(() => openLeadDrawer(lead.id), 100); showToast(`Заявка ${lead.number} сохранена`); return; }
  if (event.target.id === "track-form") { const number = new FormData(event.target).get("number"); location.hash = `#track/${String(number).trim()}`; }
});

$("#global-search")?.addEventListener("input", (event) => { ui.query = event.target.value.trim(); if (location.hash.startsWith("#office")) renderApp(); });
dom.drawerBackdrop.addEventListener("click", closeOverlays); dom.modalBackdrop.addEventListener("click", closeOverlays);
window.addEventListener("hashchange", () => { dom.marketingNav.classList.remove("open"); route(); });
window.addEventListener("scroll", () => dom.marketingHeader.classList.toggle("is-scrolled", window.scrollY > 120), { passive: true });
window.addEventListener("keydown", (event) => { if (event.key === "Escape") closeOverlays(); });

if ("serviceWorker" in navigator && location.protocol.startsWith("http")) window.addEventListener("load", () => navigator.serviceWorker.register("./sw.js").catch(() => {}));
route();
