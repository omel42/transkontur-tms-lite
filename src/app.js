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
  completionPercent,
  tripsToCsv
} from "./domain.js";
import { seedState } from "./seed.js";

const STORAGE_KEY = "transkontur-tms-lite-v2";
const app = document.querySelector("#app");
const workspace = document.querySelector("#workspace");
const modal = document.querySelector("#trip-modal");
const drawerBackdrop = document.querySelector("#drawer-backdrop");
const drawer = document.querySelector("#trip-drawer");
const searchInput = document.querySelector("#global-search");
const importInput = document.querySelector("#import-file");
const toast = document.querySelector("#toast");

let state = loadState();
let ui = { view: "dashboard", status: "all", query: "", openTripId: null };
let toastTimer;

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function loadState() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) return clone(seedState);
    const parsed = JSON.parse(stored);
    return validState(parsed) ? parsed : clone(seedState);
  } catch {
    return clone(seedState);
  }
}

function validState(value) {
  return value && Array.isArray(value.trips) && Array.isArray(value.drivers) && Array.isArray(value.vehicles);
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  updateShellCounts();
}

function esc(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function initials(name) {
  return String(name || "?")
    .split(/\s+/)
    .slice(0, 2)
    .map((word) => word[0])
    .join("")
    .toUpperCase();
}

function statusMeta(id) {
  return STATUSES.find((item) => item.id === id) || STATUSES[0];
}

function statusBadge(id) {
  const meta = statusMeta(id);
  return `<span class="status ${meta.tone}">${esc(meta.label)}</span>`;
}

function resourceStatus(status) {
  const map = {
    available: ["Свободен", "green"],
    on_trip: ["В рейсе", "violet"],
    rest: ["Отдых", "neutral"],
    service: ["Сервис", "amber"]
  };
  const [label, tone] = map[status] || [status, "neutral"];
  return `<span class="status ${tone}">${esc(label)}</span>`;
}

function getDriver(id) {
  return state.drivers.find((driver) => driver.id === id);
}

function getVehicle(id) {
  return state.vehicles.find((vehicle) => vehicle.id === id);
}

function updateShellCounts() {
  const metrics = calculateMetrics(state.trips);
  document.querySelector("#active-count").textContent = metrics.active;
  document.querySelector("#docs-count").textContent = metrics.docsIssues;
}

function pageHeader(kicker, title, subtitle, actions = "") {
  return `
    <header class="page-head">
      <div>
        <span class="eyebrow">${esc(kicker)}</span>
        <h1>${esc(title)}</h1>
        <p>${esc(subtitle)}</p>
      </div>
      ${actions ? `<div class="page-head-actions">${actions}</div>` : ""}
    </header>`;
}

function metricCard(label, value, foot, icon, footTone = "") {
  return `
    <article class="metric-card">
      <div class="metric-top"><span>${esc(label)}</span><span class="metric-icon">${icon}</span></div>
      <strong class="metric-value">${esc(value)}</strong>
      <span class="metric-foot ${footTone}">${esc(foot)}</span>
    </article>`;
}

function render() {
  document.querySelectorAll(".nav-item[data-view]").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === ui.view);
  });
  updateShellCounts();
  if (ui.view === "trips") renderTripsPage();
  else if (ui.view === "fleet") renderFleet();
  else if (ui.view === "reports") renderReports();
  else if (ui.view === "settings") renderSettings();
  else renderDashboard();
}

function renderDashboard() {
  const metrics = calculateMetrics(state.trips);
  const visible = filterTrips(state.trips, { query: ui.query })
    .filter((trip) => !["closed"].includes(trip.status))
    .slice(0, 6);
  const statusCounts = Object.fromEntries(STATUSES.map((status) => [status.id, state.trips.filter((trip) => trip.status === status.id).length]));
  const alerts = state.trips
    .filter((trip) => {
      const needsWaybill = ["loading", "in_transit", "delivered", "closed"].includes(trip.status);
      const needsClosing = ["delivered", "closed"].includes(trip.status);
      return trip.status === "issue" || !trip.docs?.request || (needsWaybill && !trip.docs?.waybill) || (needsClosing && !trip.docs?.closing);
    })
    .slice(0, 4);

  app.innerHTML = `
    ${pageHeader(
      new Intl.DateTimeFormat("ru-RU", { weekday: "long", day: "numeric", month: "long" }).format(new Date()),
      "Добрый день, Алексей",
      "Вот что происходит с перевозками сегодня."
    )}
    <section class="metrics">
      ${metricCard("Активные рейсы", metrics.active, `${statusCounts.in_transit || 0} сейчас в пути`, "↗", "good")}
      ${metricCard("Выручка по рейсам", money(metrics.revenue), "по доставленным и закрытым", "₽")}
      ${metricCard("Валовая маржа", money(metrics.margin), `${metrics.marginPercent}% от выручки`, "↟", metrics.marginPercent >= 20 ? "good" : "warn")}
      ${metricCard("Внимание к документам", metrics.docsIssues, "нет заявки или закрывающих", "!", metrics.docsIssues ? "warn" : "good")}
    </section>
    <section class="dashboard-grid">
      <div class="stack">
        <article class="panel">
          <div class="panel-head">
            <div><h2>Рейсы в работе</h2><p>${visible.length} показано · нажмите на строку для деталей</p></div>
            <div class="panel-actions"><button class="button secondary small" data-view="trips">Все рейсы</button></div>
          </div>
          <div class="pipeline">
            ${["new", "planned", "loading", "in_transit", "delivered"].map((id) => `
              <button data-view="trips" data-status="${id}"><strong>${statusCounts[id] || 0}</strong><span>${STATUS_LABEL[id]}</span></button>
            `).join("")}
          </div>
          ${tripTable(visible, true)}
        </article>
      </div>
      <div class="stack">
        <article class="panel">
          <div class="panel-head"><div><h2>Требует внимания</h2><p>Документы и отклонения</p></div></div>
          ${alerts.length ? `<div class="alert-list">${alerts.map(alertItem).join("")}</div>` : `<div class="empty"><strong>Всё спокойно</strong>Нет критичных событий.</div>`}
        </article>
        <article class="panel">
          <div class="panel-head"><div><h2>Экономика</h2><p>По завершённым рейсам</p></div><button class="text-button" data-view="reports">Подробнее →</button></div>
          <div class="mini-economy">
            <div class="economy-row"><span>Выручка</span><div class="bar-track"><div class="bar-fill" style="width:100%"></div></div><b>${compactMoney(metrics.revenue)}</b></div>
            <div class="economy-row"><span>Затраты</span><div class="bar-track"><div class="bar-fill accent" style="width:${metrics.revenue ? Math.round(((metrics.revenue - metrics.margin) / metrics.revenue) * 100) : 0}%"></div></div><b>${compactMoney(metrics.revenue - metrics.margin)}</b></div>
            <div class="economy-row"><span>Маржа</span><div class="bar-track"><div class="bar-fill green" style="width:${Math.max(0, metrics.marginPercent)}%"></div></div><b>${metrics.marginPercent}%</b></div>
          </div>
        </article>
      </div>
    </section>`;
}

function compactMoney(value) {
  return `${new Intl.NumberFormat("ru-RU", { notation: "compact", maximumFractionDigits: 1 }).format(value || 0)} ₽`;
}

function alertItem(trip) {
  let text = "Не прикреплена заявка клиента";
  if (trip.status === "issue") text = "По рейсу зафиксирована проблема";
  else if (["delivered", "closed"].includes(trip.status) && !trip.docs?.closing) text = "Ожидаются закрывающие документы";
  else if (["loading", "in_transit", "delivered", "closed"].includes(trip.status) && !trip.docs?.waybill) text = "Нет транспортной накладной / ЭПД";
  return `
    <div class="alert">
      <span class="alert-icon">!</span>
      <span><strong>${esc(trip.number)} · ${esc(trip.client)}</strong><small>${esc(text)}</small></span>
      <button data-action="open-trip" data-id="${esc(trip.id)}" aria-label="Открыть рейс">→</button>
    </div>`;
}

function tripTable(trips, compact = false) {
  if (!trips.length) return `<div class="empty"><strong>Рейсы не найдены</strong>Измените фильтр или создайте новый рейс.</div>`;
  return `
    <div class="table-wrap">
      <table class="data-table">
        <thead><tr><th>Рейс</th><th>Маршрут</th><th>Погрузка</th><th>Экипаж</th><th>Статус</th>${compact ? "" : "<th>Цена</th><th>Маржа</th>"}</tr></thead>
        <tbody>
          ${trips.map((trip) => {
            const driver = getDriver(trip.driverId);
            const vehicle = getVehicle(trip.vehicleId);
            return `
              <tr data-id="${esc(trip.id)}">
                <td><span class="number">${esc(trip.number)}</span><div class="route"><span>${esc(trip.client)}</span></div></td>
                <td><div class="route"><strong>${esc(trip.from)} → ${esc(trip.to)}</strong><span>${esc(trip.cargo)}${trip.weight ? ` · ${esc(trip.weight)} т` : ""}</span></div></td>
                <td>${esc(shortDate(trip.pickupAt))}</td>
                <td><div class="route"><strong>${esc(driver?.name || "Не назначен")}</strong><span>${esc(vehicle?.plate || "Нет машины")}</span></div></td>
                <td>${statusBadge(trip.status)}</td>
                ${compact ? "" : `<td>${esc(money(trip.price))}</td><td class="money-positive">${esc(money(tripMargin(trip)))}</td>`}
              </tr>`;
          }).join("")}
        </tbody>
      </table>
    </div>`;
}

function renderTripsPage() {
  const visible = filterTrips(state.trips, { query: ui.query, status: ui.status });
  app.innerHTML = `
    ${pageHeader("Диспетчерская", "Все рейсы", "Единый список заявок, назначений и статусов.", `<button class="button secondary" data-action="export-csv">Выгрузить CSV</button>`)}
    <div class="filters">
      ${[{ id: "all", label: "Все" }, ...STATUSES].map((item) => `<button class="filter-chip ${ui.status === item.id ? "active" : ""}" data-status-filter="${item.id}">${esc(item.label)}</button>`).join("")}
      <span class="filter-spacer"></span><span class="result-count">Найдено: ${visible.length}</span>
    </div>
    <article class="panel">${tripTable(visible)}</article>`;
}

function renderFleet() {
  app.innerHTML = `
    ${pageHeader("Ресурсы", "Автопарк и водители", "Кто доступен для назначения на следующий рейс.")}
    <section class="fleet-grid">
      <article class="panel">
        <div class="panel-head"><div><h2>Водители</h2><p>${state.drivers.length} в справочнике</p></div></div>
        <div class="resource-list">${state.drivers.map((driver) => `
          <div class="resource"><span class="resource-avatar">${esc(initials(driver.name))}</span><span class="resource-info"><b>${esc(driver.name)}</b><small>${esc(driver.phone)} · ВУ ${esc(driver.license)}</small></span>${resourceStatus(driver.status)}</div>
        `).join("")}</div>
        <form class="inline-form" id="driver-form">
          <label class="field"><span>ФИО</span><input name="name" required placeholder="Новый водитель" /></label>
          <label class="field"><span>Телефон</span><input name="phone" required placeholder="+7 900 000-00-00" /></label>
          <button class="button primary" type="submit">Добавить</button>
        </form>
      </article>
      <article class="panel">
        <div class="panel-head"><div><h2>Автомобили</h2><p>${state.vehicles.length} в справочнике</p></div></div>
        <div class="resource-list">${state.vehicles.map((vehicle) => `
          <div class="resource"><span class="resource-avatar truck">▰</span><span class="resource-info"><b>${esc(vehicle.plate)}</b><small>${esc(vehicle.model)} · ${esc(vehicle.type)}</small></span>${resourceStatus(vehicle.status)}</div>
        `).join("")}</div>
        <form class="inline-form" id="vehicle-form">
          <label class="field"><span>Госномер</span><input name="plate" required placeholder="А 000 АА 77" /></label>
          <label class="field"><span>Модель</span><input name="model" required placeholder="КАМАЗ" /></label>
          <button class="button primary" type="submit">Добавить</button>
        </form>
      </article>
    </section>`;
}

function renderReports() {
  const completed = state.trips.filter((trip) => ["delivered", "closed"].includes(trip.status));
  const basis = completed.length ? completed : state.trips;
  const metrics = calculateMetrics(state.trips);
  const maxMargin = Math.max(1, ...basis.map((trip) => Math.max(0, tripMargin(trip))));
  const clients = Object.values(basis.reduce((result, trip) => {
    result[trip.client] ||= { name: trip.client, count: 0, revenue: 0, margin: 0 };
    result[trip.client].count += 1;
    result[trip.client].revenue += Number(trip.price || 0);
    result[trip.client].margin += tripMargin(trip);
    return result;
  }, {})).sort((a, b) => b.revenue - a.revenue);

  app.innerHTML = `
    ${pageHeader("Финансы", "Экономика рейсов", "План-факт без замены бухгалтерского учёта.", `<button class="button secondary" data-action="export-csv">Выгрузить CSV</button>`)}
    <section class="metrics">
      ${metricCard("Выручка", money(metrics.revenue), `${basis.length} рейсов в расчёте`, "₽")}
      ${metricCard("Валовая маржа", money(metrics.margin), `${metrics.marginPercent}% от выручки`, "↟", "good")}
      ${metricCard("Средняя маржа", money(basis.length ? metrics.margin / basis.length : 0), "на один рейс", "≈")}
      ${metricCard("Средний чек", money(basis.length ? metrics.revenue / basis.length : 0), "на один рейс", "◉")}
    </section>
    <section class="report-grid">
      <article class="panel">
        <div class="panel-head"><div><h2>Маржа по рейсам</h2><p>Цена минус фактические или плановые затраты</p></div></div>
        <div class="bars">
          ${basis.map((trip) => `<div class="report-bar"><label>${esc(trip.number)} · ${esc(trip.client)}</label><div class="bar-track"><div class="bar-fill green" style="width:${Math.max(2, Math.round((Math.max(0, tripMargin(trip)) / maxMargin) * 100))}%"></div></div><strong>${esc(money(tripMargin(trip)))}</strong></div>`).join("")}
        </div>
      </article>
      <article class="panel">
        <div class="panel-head"><div><h2>Клиенты</h2><p>Вклад в выручку</p></div></div>
        <div class="client-table">
          ${clients.map((client) => `<div class="client-row"><span><b>${esc(client.name)}</b><small>${client.count} рейс. · маржа ${esc(money(client.margin))}</small></span><b>${esc(money(client.revenue))}</b></div>`).join("")}
        </div>
      </article>
    </section>`;
}

function renderSettings() {
  app.innerHTML = `
    ${pageHeader("MVP", "Данные и перенос", "Экспортируйте демо-данные или загрузите сохранённую копию.")}
    <section class="settings-grid">
      <article class="panel settings-card">
        <h2>Резервная копия</h2>
        <p>JSON содержит рейсы, водителей и автомобили. Его можно перенести в другой браузер.</p>
        <div class="button-row"><button class="button primary" data-action="export-json">Скачать JSON</button><button class="button secondary" data-action="import-json">Загрузить JSON</button></div>
      </article>
      <article class="panel settings-card">
        <h2>Отчёт для Excel</h2>
        <p>CSV с маршрутами, статусами, выручкой, затратами и маржой по каждому рейсу.</p>
        <div class="button-row"><button class="button primary" data-action="export-csv">Скачать CSV</button></div>
      </article>
      <article class="panel settings-card">
        <h2>Границы этой версии</h2>
        <p>Это проверяемый локальный MVP, а не промышленная TMS.</p>
        <div class="scope-note">Данные находятся только в этом браузере. Клиентская ссылка демонстрационная и открывает актуальный статус только на устройстве диспетчера. Для пилота понадобятся сервер, авторизация, резервные копии и интеграция с оператором ИС ЭПД.</div>
      </article>
      <article class="panel settings-card">
        <h2>Начать демо заново</h2>
        <p>Удаляет локальные изменения и возвращает исходные примеры рейсов.</p>
        <div class="button-row"><button class="button danger" data-action="reset-demo">Сбросить демо</button></div>
      </article>
    </section>`;
}

function renderDrawer(id) {
  const trip = state.trips.find((item) => item.id === id);
  if (!trip) return closeDrawer();
  ui.openTripId = id;
  const driver = getDriver(trip.driverId);
  const vehicle = getVehicle(trip.vehicleId);
  const cost = Number(trip.actualCost || trip.plannedCost || 0);
  drawer.innerHTML = `
    <header class="drawer-head">
      <div class="drawer-head-row">
        <div><span class="eyebrow">Рейс ${esc(trip.number)}</span><h2>${esc(trip.from)} → ${esc(trip.to)}</h2><p>${esc(trip.client)} · ${esc(trip.cargo)}</p></div>
        <button class="icon-button" data-action="close-drawer" aria-label="Закрыть">×</button>
      </div>
      <div class="drawer-progress"><span style="width:${completionPercent(trip.status)}%"></span></div>
    </header>
    <div class="drawer-body">
      <section class="drawer-section">
        <h3>Маршрут</h3>
        <div class="route-card">
          <div class="route-line"><i class="route-dot"></i><i class="route-dot"></i></div>
          <div class="route-points">
            <div class="route-point"><b>${esc(trip.from)}</b><small>Погрузка · ${esc(dateTime(trip.pickupAt))}</small></div>
            <div class="route-point"><b>${esc(trip.to)}</b><small>Выгрузка · ${esc(dateTime(trip.deliveryAt))}</small></div>
          </div>
        </div>
      </section>
      <section class="drawer-section">
        <h3>Статус и действие</h3>
        <div class="drawer-controls">
          <select class="status-select" data-action="change-status" data-id="${esc(trip.id)}">
            ${STATUSES.map((status) => `<option value="${status.id}" ${trip.status === status.id ? "selected" : ""}>${esc(status.label)}</option>`).join("")}
          </select>
          ${trip.status !== "closed" ? `<button class="button primary" data-action="advance-status" data-id="${esc(trip.id)}">Дальше: ${esc(STATUS_LABEL[NEXT_STATUS[trip.status]])}</button>` : ""}
        </div>
      </section>
      <section class="drawer-section">
        <h3>Назначение</h3>
        <form class="assignment-form" id="assignment-form" data-id="${esc(trip.id)}">
          <label class="field"><span>Водитель</span><select name="driverId"><option value="">Не назначен</option>${state.drivers.map((item) => `<option value="${esc(item.id)}" ${item.id === trip.driverId ? "selected" : ""}>${esc(item.name)}</option>`).join("")}</select></label>
          <label class="field"><span>Автомобиль</span><select name="vehicleId"><option value="">Не назначен</option>${state.vehicles.map((item) => `<option value="${esc(item.id)}" ${item.id === trip.vehicleId ? "selected" : ""}>${esc(item.plate)} · ${esc(item.model)}</option>`).join("")}</select></label>
          <button class="button secondary" type="submit">Сохранить назначение</button>
        </form>
        <div class="facts" style="margin-top:10px">
          <div class="fact"><span>Груз</span><b>${esc(trip.cargo)}${trip.weight ? ` · ${esc(trip.weight)} т` : ""}</b></div>
          <div class="fact"><span>Контакт клиента</span><b>${esc(trip.contact || "—")} ${esc(trip.phone || "")}</b></div>
        </div>
      </section>
      <section class="drawer-section">
        <h3>Экономика</h3>
        <div class="facts">
          <div class="fact"><span>Цена клиенту</span><b>${esc(money(trip.price))}</b></div>
          <div class="fact"><span>Текущие затраты</span><b>${esc(money(cost))}</b></div>
          <div class="fact"><span>Маржа</span><b class="good">${esc(money(tripMargin(trip)))}</b></div>
          <div class="fact"><span>Рентабельность</span><b class="good">${marginPercent(trip)}%</b></div>
        </div>
        <form class="cost-edit" id="cost-form" data-id="${esc(trip.id)}" style="margin-top:10px">
          <label class="field"><span>Фактические затраты, ₽</span><input name="actualCost" type="number" min="0" value="${trip.actualCost || ""}" placeholder="Пока используем план" /></label>
          <button class="button secondary" type="submit">Сохранить</button>
        </form>
      </section>
      <section class="drawer-section">
        <h3>Документы</h3>
        <div class="doc-list">
          ${docCheck(trip, "request", "Заявка клиента")}
          ${docCheck(trip, "waybill", "Транспортная накладная / ЭПД")}
          ${docCheck(trip, "closing", "Акт и закрывающие документы")}
        </div>
      </section>
      ${trip.comment ? `<section class="drawer-section"><h3>Комментарий</h3><div class="client-note">${esc(trip.comment)}</div></section>` : ""}
      <section class="drawer-section">
        <h3>История</h3>
        <div class="timeline">${[...(trip.events || [])].reverse().map((event) => `<div class="timeline-item"><b>${esc(event.note)}</b><small>${esc(dateTime(event.at))}</small></div>`).join("")}</div>
      </section>
      <section class="drawer-section">
        <h3>Клиент</h3>
        <button class="button secondary" data-action="copy-client" data-id="${esc(trip.id)}">Скопировать ссылку на статус</button>
      </section>
    </div>`;
  drawerBackdrop.hidden = false;
  document.body.style.overflow = "hidden";
}

function docCheck(trip, key, label) {
  return `<label class="doc-check"><input type="checkbox" data-doc="${key}" data-id="${esc(trip.id)}" ${trip.docs?.[key] ? "checked" : ""} /><span>${esc(label)}</span></label>`;
}

function closeDrawer() {
  drawerBackdrop.hidden = true;
  document.body.style.overflow = "";
  ui.openTripId = null;
}

function openNewTrip() {
  const driverSelect = document.querySelector("#driver-select");
  const vehicleSelect = document.querySelector("#vehicle-select");
  driverSelect.innerHTML = `<option value="">Назначить позже</option>${state.drivers.map((driver) => `<option value="${esc(driver.id)}">${esc(driver.name)}</option>`).join("")}`;
  vehicleSelect.innerHTML = `<option value="">Назначить позже</option>${state.vehicles.map((vehicle) => `<option value="${esc(vehicle.id)}">${esc(vehicle.plate)} · ${esc(vehicle.model)}</option>`).join("")}`;
  const form = document.querySelector("#trip-form");
  form.reset();
  const pickup = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const delivery = new Date(Date.now() + 48 * 60 * 60 * 1000);
  form.elements.pickupAt.value = toLocalInput(pickup);
  form.elements.deliveryAt.value = toLocalInput(delivery);
  modal.hidden = false;
  document.body.style.overflow = "hidden";
  setTimeout(() => form.elements.client.focus(), 0);
}

function toLocalInput(date) {
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
}

function closeModal() {
  modal.hidden = true;
  document.body.style.overflow = "";
}

function showToast(message) {
  clearTimeout(toastTimer);
  toast.textContent = message;
  toast.hidden = false;
  toastTimer = setTimeout(() => { toast.hidden = true; }, 2800);
}

function setView(view, status) {
  ui.view = view;
  if (status) ui.status = status;
  workspace.classList.remove("menu-open");
  closeDrawer();
  render();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function download(filename, content, type) {
  const url = URL.createObjectURL(new Blob([content], { type }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

async function copyClientLink(id) {
  const url = new URL(window.location.href);
  url.search = "";
  url.searchParams.set("client", id);
  try {
    await navigator.clipboard.writeText(url.toString());
    showToast("Ссылка на статус скопирована");
  } catch {
    window.prompt("Скопируйте ссылку", url.toString());
  }
}

function renderClientPage(id) {
  const trip = state.trips.find((item) => item.id === id);
  document.body.innerHTML = `
    <main class="client-page">
      <div class="client-shell">
        <div class="client-brand"><span class="brand-mark">ТК</span><span><b>ТрансКонтур</b><small style="display:block;color:var(--muted);margin-top:2px">Статус перевозки</small></span></div>
        ${trip ? clientTripCard(trip) : `<article class="client-card"><div class="client-content empty"><strong>Рейс не найден</strong>Ссылка устарела или данные находятся в другом браузере.<br><br><a class="button secondary" href="${esc(location.pathname)}">Вернуться</a></div></article>`}
      </div>
    </main>`;
}

function clientTripCard(trip) {
  const driver = getDriver(trip.driverId);
  const steps = ["planned", "loading", "in_transit", "delivered", "closed"];
  const doneIndex = steps.indexOf(trip.status);
  const lastEvent = trip.events?.at(-1);
  return `
    <article class="client-card">
      <header class="client-hero"><span class="eyebrow">Перевозка ${esc(trip.number)}</span><h1>${esc(trip.from)} → ${esc(trip.to)}</h1><p>${esc(trip.cargo)}${trip.weight ? ` · ${esc(trip.weight)} т` : ""}</p></header>
      <div class="client-content">
        ${statusBadge(trip.status)}
        <div class="client-progress">${steps.map((_, index) => `<span class="${index <= doneIndex ? "done" : ""}"></span>`).join("")}</div>
        <div class="facts">
          <div class="fact"><span>Погрузка</span><b>${esc(dateTime(trip.pickupAt))}</b></div>
          <div class="fact"><span>Плановая доставка</span><b>${esc(dateTime(trip.deliveryAt))}</b></div>
          <div class="fact"><span>Водитель</span><b>${esc(driver?.name || "Назначается")}</b></div>
          <div class="fact"><span>Автомобиль</span><b>${esc(getVehicle(trip.vehicleId)?.plate || "Назначается")}</b></div>
        </div>
        <section style="margin-top:26px"><h3 style="font-size:11px;text-transform:uppercase;letter-spacing:.08em">Последнее событие</h3><div class="client-note"><b>${esc(lastEvent?.note || "Заявка принята")}</b><br>${esc(dateTime(lastEvent?.at || trip.createdAt))}</div></section>
        <p style="margin:22px 0 0;color:var(--muted);font-size:9px">Статус обновляет диспетчер перевозчика. Если время доставки изменится, с вами свяжутся.</p>
      </div>
    </article>`;
}

document.addEventListener("click", (event) => {
  const viewButton = event.target.closest("[data-view]");
  if (viewButton) {
    setView(viewButton.dataset.view, viewButton.dataset.status);
    return;
  }

  const action = event.target.closest("[data-action]");
  if (action) {
    const id = action.dataset.id;
    if (action.dataset.action === "new-trip") openNewTrip();
    if (action.dataset.action === "close-modal") closeModal();
    if (action.dataset.action === "open-trip") renderDrawer(id);
    if (action.dataset.action === "close-drawer") closeDrawer();
    if (action.dataset.action === "advance-status") {
      const trip = state.trips.find((item) => item.id === id);
      if (trip) {
        Object.assign(trip, updateTripStatus(trip, NEXT_STATUS[trip.status]));
        saveState();
        render();
        renderDrawer(id);
        showToast(`Рейс ${trip.number}: ${STATUS_LABEL[trip.status]}`);
      }
    }
    if (action.dataset.action === "copy-client") copyClientLink(id);
    if (action.dataset.action === "export-json") download(`transkontur-${new Date().toISOString().slice(0, 10)}.json`, JSON.stringify(state, null, 2), "application/json");
    if (action.dataset.action === "export-csv") download(`reysy-${new Date().toISOString().slice(0, 10)}.csv`, `\ufeff${tripsToCsv(state.trips)}`, "text/csv;charset=utf-8");
    if (action.dataset.action === "import-json") importInput.click();
    if (action.dataset.action === "reset-demo" && window.confirm("Сбросить локальные изменения и вернуть демо-данные?")) {
      state = clone(seedState);
      saveState();
      render();
      showToast("Демо-данные восстановлены");
    }
    return;
  }

  const filter = event.target.closest("[data-status-filter]");
  if (filter) {
    ui.status = filter.dataset.statusFilter;
    renderTripsPage();
    return;
  }

  const row = event.target.closest("tr[data-id]");
  if (row) renderDrawer(row.dataset.id);

  if (event.target === modal) closeModal();
  if (event.target === drawerBackdrop) closeDrawer();
});

document.addEventListener("change", (event) => {
  const statusSelect = event.target.closest('[data-action="change-status"]');
  if (statusSelect) {
    const trip = state.trips.find((item) => item.id === statusSelect.dataset.id);
    if (trip) {
      Object.assign(trip, updateTripStatus(trip, statusSelect.value));
      saveState();
      render();
      renderDrawer(trip.id);
      showToast(`Статус изменён: ${STATUS_LABEL[trip.status]}`);
    }
  }
  const doc = event.target.closest("[data-doc]");
  if (doc) {
    const trip = state.trips.find((item) => item.id === doc.dataset.id);
    if (trip) {
      trip.docs ||= {};
      trip.docs[doc.dataset.doc] = doc.checked;
      saveState();
      render();
      renderDrawer(trip.id);
      showToast("Документы обновлены");
    }
  }
});

document.addEventListener("submit", (event) => {
  event.preventDefault();
  const form = event.target;
  const data = Object.fromEntries(new FormData(form));
  if (form.id === "trip-form") {
    const trip = createTrip(data, state);
    state.trips.unshift(trip);
    saveState();
    closeModal();
    setView("trips");
    renderDrawer(trip.id);
    showToast(`Рейс ${trip.number} создан`);
  }
  if (form.id === "driver-form") {
    state.drivers.push({ id: `d-${Date.now()}`, name: data.name.trim(), phone: data.phone.trim(), license: "не указан", status: "available" });
    saveState();
    renderFleet();
    showToast("Водитель добавлен");
  }
  if (form.id === "vehicle-form") {
    state.vehicles.push({ id: `v-${Date.now()}`, plate: data.plate.trim().toUpperCase(), model: data.model.trim(), type: "Тип не указан", status: "available" });
    saveState();
    renderFleet();
    showToast("Автомобиль добавлен");
  }
  if (form.id === "cost-form") {
    const trip = state.trips.find((item) => item.id === form.dataset.id);
    if (trip) {
      trip.actualCost = Number(data.actualCost || 0);
      saveState();
      render();
      renderDrawer(trip.id);
      showToast("Фактические затраты сохранены");
    }
  }
  if (form.id === "assignment-form") {
    const trip = state.trips.find((item) => item.id === form.dataset.id);
    if (trip) {
      trip.driverId = data.driverId || "";
      trip.vehicleId = data.vehicleId || "";
      const assigned = Boolean(trip.driverId && trip.vehicleId);
      if (assigned && trip.status === "new") {
        Object.assign(trip, updateTripStatus(trip, "planned"));
      } else {
        trip.events = [...(trip.events || []), { at: new Date().toISOString(), status: trip.status, note: assigned ? "Экипаж переназначен" : "Назначение экипажа изменено" }];
      }
      saveState();
      render();
      renderDrawer(trip.id);
      showToast(assigned ? "Экипаж назначен" : "Назначение сохранено");
    }
  }
});

searchInput.addEventListener("input", () => {
  ui.query = searchInput.value;
  if (ui.view === "dashboard") renderDashboard();
  if (ui.view === "trips") renderTripsPage();
});

searchInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter") setView("trips");
});

document.querySelector("#mobile-menu").addEventListener("click", () => workspace.classList.toggle("menu-open"));

document.addEventListener("keydown", (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
    event.preventDefault();
    searchInput.focus();
  }
  if (event.key === "Escape") {
    closeModal();
    closeDrawer();
    workspace.classList.remove("menu-open");
  }
});

importInput.addEventListener("change", async () => {
  const file = importInput.files?.[0];
  if (!file) return;
  try {
    const imported = JSON.parse(await file.text());
    if (!validState(imported)) throw new Error("bad shape");
    state = imported;
    saveState();
    render();
    showToast("Данные загружены");
  } catch {
    showToast("Не удалось загрузить: неверный формат файла");
  } finally {
    importInput.value = "";
  }
});

const clientId = new URLSearchParams(location.search).get("client");
if (clientId) {
  renderClientPage(clientId);
} else {
  render();
  if ("serviceWorker" in navigator && location.protocol.startsWith("http")) {
    navigator.serviceWorker.register("./sw.js").catch(() => {});
  }
}
