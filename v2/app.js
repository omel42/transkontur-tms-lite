const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const esc = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" }[char]));

const STORAGE_KEY = "transkontur-epd-v2-demo";
const initialState = {
  screen: "queue",
  innFixed: false,
  t2Sent: false,
  t2Signed: false,
  closingDone: false,
  pilot: null
};

let demoState = loadState();
let toastTimer;

const documentRoles = {
  forwarder: {
    title: "ООО организует перевозку чужой машиной",
    copy: "Компания принимает поручение клиента, привлекает перевозчика и отвечает за экспедиционную часть процесса.",
    warning: "Нужно проверить включение ООО в реестр экспедиторов «ГосЛог».",
    documents: [
      ["ПЭ", "Поручение экспедитору", "Что клиент поручил сделать, условия и свойства груза.", "до принятия груза", "Обязательно"],
      ["ЭР", "Экспедиторская расписка", "Подтверждает, что экспедитор принял груз в своё ведение.", "при приёме", "Обязательно"],
      ["ЭЗЗ", "Заказ / заявка на перевозку", "Маршрут, груз, машина, водитель и согласованные условия.", "до подачи машины", "По сценарию"],
      ["ТрН", "Электронная транспортная накладная", "Юридически значимый набор XML-титулов по движению груза.", "погрузка → выгрузка", "Ключевой"],
      ["СР", "Складская расписка", "Нужна, если экспедитор принимает груз на складское хранение.", "при хранении", "По ситуации"],
      ["₽", "УПД / акт / счёт", "Закрывает услугу и запускает оплату после подтверждения перевозки.", "после выгрузки", "Финансы"]
    ]
  },
  carrier: {
    title: "ООО принимает груз и везёт своей машиной",
    copy: "Компания отвечает за транспорт, водителя, принятие груза и исполнение договора перевозки.",
    warning: "С 1 марта 2027 года запускается реестр автомобильных перевозчиков «ГосЛог».",
    documents: [
      ["ЭЗЗ", "Заказ / заявка на перевозку", "Согласованные условия, маршрут, груз и требования к машине.", "до рейса", "По сценарию"],
      ["ТрН", "Электронная транспортная накладная", "Титулы грузоотправителя, перевозчика и грузополучателя.", "погрузка → выгрузка", "Ключевой"],
      ["ПЛ", "Электронный путевой лист", "Реквизиты ТС, водителя, выпуска на линию и обязательных осмотров.", "до выезда", "Для своего парка"],
      ["QR", "Код проверки перевозки", "Формируется после необходимых первых титулов и предъявляется в дороге.", "до движения", "Контроль"],
      ["Т8", "Изменение машины или водителя", "Позволяет продолжить документооборот без создания новой ЭТрН.", "при замене", "Исключение"],
      ["₽", "УПД / акт / счёт", "Связывает завершённый рейс с закрывающими документами и оплатой.", "после выгрузки", "Финансы"]
    ]
  }
};

function loadState() {
  try {
    return { ...initialState, ...JSON.parse(localStorage.getItem(STORAGE_KEY)) };
  } catch (_) {
    return { ...initialState };
  }
}

function saveState() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(demoState));
}

function showToast(message) {
  const toast = $("[data-toast]");
  clearTimeout(toastTimer);
  toast.textContent = message;
  toast.classList.add("show");
  toastTimer = setTimeout(() => toast.classList.remove("show"), 2600);
}

function scrollToDemo() {
  $("#demo")?.scrollIntoView({ behavior: "smooth", block: "start" });
}

function renderDocumentRole(role) {
  const content = documentRoles[role] || documentRoles.forwarder;
  $("[data-role-title]").textContent = content.title;
  $("[data-role-copy]").textContent = content.copy;
  $("[data-role-warning]").textContent = content.warning;
  $("[data-doc-stack]").innerHTML = content.documents.map(([mark, title, copy, moment, tag], index) => `
    <article class="document-card">
      <span class="doc-icon${index === 3 ? " doc-icon--alert" : ""}">${esc(mark)}</span>
      <div><h3>${esc(title)}</h3><p>${esc(copy)}</p></div>
      <div class="doc-meta"><span class="state ${index === 3 ? "state--wait" : "state--done"}">${esc(tag)}</span><small>${esc(moment)}</small></div>
    </article>
  `).join("");
}

function unresolvedCount() {
  return Number(!demoState.innFixed) + Number(!demoState.t2Signed) + Number(!demoState.closingDone);
}

function taskRow({ tone, title, copy, action, actionLabel, done = false }) {
  return `<article class="task-row${done ? " is-complete" : ""}">
    <i class="task-tone task-tone--${tone}"></i>
    <div><strong>${title}</strong><p>${copy}</p></div>
    ${action ? `<button class="mini-action" type="button" data-demo-action="${action}" ${done ? "disabled" : ""}>${done ? "Готово ✓" : actionLabel}</button>` : ""}
  </article>`;
}

function queueScreen() {
  const t2Label = demoState.t2Sent ? "Подтвердить подпись" : "Отправить";
  const t2Action = demoState.t2Sent ? "sign-t2" : "send-t2";
  const pilot = demoState.pilot ? taskRow({
    tone: "blue",
    title: `Пилот · ${esc(demoState.pilot.role)} · ${esc(demoState.pilot.operator)}`,
    copy: esc(demoState.pilot.pain || "Разобрать один реальный рейс и отметить повторяющиеся ручные шаги."),
    action: "open-trip",
    actionLabel: "Открыть"
  }) : "";

  return `
    <div class="screen-heading"><div><small>ОПЕРАЦИОННЫЙ ЦЕНТР</small><h3>Что требует решения</h3><p>Показываем исключения — нормальный ход рейса система ведёт сама.</p></div><button class="button button--dark button--compact" type="button" data-demo-action="open-trip">Рейс TK-24031 →</button></div>
    <section class="demo-stats">
      <article class="demo-stat demo-stat--dark"><small>ТРЕБУЮТ РЕАКЦИИ</small><strong>${unresolvedCount()}</strong><p>задачи на сегодня</p></article>
      <article class="demo-stat"><small>ЖДУТ ПОДПИСИ</small><strong>${demoState.t2Signed ? 0 : 1}</strong><p>${demoState.t2Signed ? "очередь чиста" : "перевозчик · Т2"}</p></article>
      <article class="demo-stat"><small>ОШИБКИ XML</small><strong>${demoState.innFixed ? 0 : 1}</strong><p>${demoState.innFixed ? "проверка пройдена" : "ИНН грузополучателя"}</p></article>
      <article class="demo-stat"><small>QR ГОТОВ</small><strong>${demoState.t2Signed ? 4 : 3}</strong><p>из 4 активных рейсов</p></article>
    </section>
    <div class="demo-grid">
      <section class="demo-panel">
        <div class="demo-panel-head"><h4>Очередь действий</h4><small>по приоритету</small></div>
        <div class="task-list">
          ${taskRow({ tone: "red", title: "ЭТрН TK-24033 отклонена проверкой", copy: "ИНН грузополучателя содержит 9 цифр вместо 10.", action: "fix-inn", actionLabel: "Исправить", done: demoState.innFixed })}
          ${taskRow({ tone: "amber", title: demoState.t2Signed ? "Титул Т2 подписан перевозчиком" : "Перевозчик не подписал титул Т2", copy: demoState.t2Signed ? "QR-код сформирован и доступен водителю." : "Рейс TK-24031 · без подписи QR пока не сформирован.", action: t2Action, actionLabel: t2Label, done: demoState.t2Signed })}
          ${taskRow({ tone: "green", title: demoState.closingDone ? "Закрывающие TK-24029 получены" : "Запросить закрывающие по TK-24029", copy: demoState.closingDone ? "Пакет передан в финансовую очередь." : "Выгрузка завершена вчера, акт и УПД ещё не загружены.", action: "closing", actionLabel: "Запросить", done: demoState.closingDone })}
          ${pilot}
        </div>
      </section>
      <aside class="demo-panel attention-card">
        <small>ГОТОВНОСТЬ TK-24031</small>
        <div class="attention-score"><div class="score-ring"><strong>${demoState.t2Signed ? 100 : 67}%</strong></div><p>${demoState.t2Signed ? "Документы готовы. QR передан водителю." : "Остался один блокирующий шаг до выезда."}</p></div>
        <div class="next-list">
          <div><span>✓</span><p>Заказ-заявка согласована</p></div>
          <div><span>✓</span><p>Титул Т1 подписан</p></div>
          <div><span>${demoState.t2Signed ? "✓" : "3"}</span><p>${demoState.t2Signed ? "Титул Т2 подписан" : "Получить подпись Т2"}</p></div>
          <div><span>${demoState.t2Signed ? "✓" : "4"}</span><p>${demoState.t2Signed ? "QR сформирован" : "Передать QR водителю"}</p></div>
        </div>
      </aside>
    </div>`;
}

function tripScreen() {
  const qrLocked = !demoState.t2Signed;
  return `
    <div class="screen-heading"><div><small>КАРТОЧКА ПЕРЕВОЗКИ</small><h3>TK-24031 · Спектр Маркет</h3><p>Все договорённости, участники, документы и события в одном месте.</p></div><span class="pill pill--moving">${demoState.t2Signed ? "В пути" : "На погрузке"}</span></div>
    <section class="trip-hero-demo">
      <div><small>МАРШРУТ</small><h3>Москва → Казань</h3><p>Бытовая техника · 18 т · тент · выгрузка 15 сент., 20:00</p></div>
      <div class="qr-placeholder${qrLocked ? " is-locked" : ""}"><span>${qrLocked ? "QR ЖДЁТ Т2" : "QR ГОТОВ"}</span></div>
    </section>
    <div class="trip-facts">
      <div><small>КЛИЕНТ</small><strong>Спектр Маркет</strong></div>
      <div><small>ПЕРЕВОЗЧИК</small><strong>ООО «Вектор»</strong></div>
      <div><small>ВОДИТЕЛЬ</small><strong>Максим Орлов</strong></div>
      <div><small>МАШИНА</small><strong>М 547 КТ 799</strong></div>
    </div>
    <section class="demo-panel">
      <div class="demo-panel-head"><h4>Юридический пакет рейса</h4><small>XML · подписи · события</small></div>
      <div class="demo-doc-list">
        ${docRow("ЭЗЗ", "Заказ-заявка №31", "Клиент и экспедитор · 2 подписи", "done", "Согласовано")}
        ${docRow("Т1", "ЭТрН · данные грузоотправителя", "XML проверен · подписано 14 сент., 08:42", "done", "Подписан")}
        ${docRow("Т2", "ЭТрН · приём груза перевозчиком", demoState.t2Signed ? "Подписано перевозчиком · QR сформирован" : demoState.t2Sent ? "Запрос отправлен · ждём ООО «Вектор»" : "Готов к отправке оператору", demoState.t2Signed ? "done" : "wait", demoState.t2Signed ? "Подписан" : demoState.t2Sent ? "Ждём" : "Отправить", demoState.t2Signed ? "" : demoState.t2Sent ? "sign-t2" : "send-t2")}
        ${docRow("QR", "Код проверки ГИС ЭПД", qrLocked ? "Разблокируется после подписи титула Т2" : "Доступен водителю и для проверки в дороге", qrLocked ? "locked" : "done", qrLocked ? "Заблокирован" : "Готов")}
        ${docRow("ВГ", "Подтверждение выгрузки", "Появится после прибытия в Казань", "locked", "Позже")}
        ${docRow("₽", "УПД, акт и счёт", "Формируются после завершения перевозки", "locked", "Позже")}
      </div>
    </section>`;
}

function docRow(mark, title, copy, tone, label, action = "") {
  return `<article class="demo-doc-row">
    <span class="doc-icon${tone === "wait" || tone === "error" ? " doc-icon--alert" : ""}">${mark}</span>
    <div><strong>${title}</strong><p>${copy}</p></div>
    ${action ? `<button class="mini-action" type="button" data-demo-action="${action}">${label}</button>` : `<span class="doc-stage doc-stage--${tone}">${label}</span>`}
  </article>`;
}

function docsScreen() {
  return `
    <div class="screen-heading"><div><small>ДОКУМЕНТЫ</small><h3>Пакеты по рейсам</h3><p>Не архив файлов, а состояние исполнения каждой перевозки.</p></div><button class="button button--dark button--compact" type="button" data-demo-action="open-trip">Открыть TK-24031 →</button></div>
    <section class="demo-panel">
      <div class="demo-panel-head"><h4>Активный пакет · TK-24031</h4><small>${demoState.t2Signed ? "5 из 6 готовы" : "4 из 6 готовы"}</small></div>
      <div class="demo-doc-list">
        ${docRow("ПЭ", "Поручение экспедитору", "Спектр Маркет → ТрансКонтур", "done", "Подписан")}
        ${docRow("ЭР", "Экспедиторская расписка", "Груз принят в ведение", "done", "Подписан")}
        ${docRow("ЭЗЗ", "Заказ-заявка", "Условия перевозки согласованы", "done", "Подписан")}
        ${docRow("ТрН", "Электронная транспортная накладная", demoState.t2Signed ? "Т1 и Т2 подписаны · QR готов" : "Т1 подписан · Т2 ожидает перевозчика", demoState.t2Signed ? "done" : "wait", demoState.t2Signed ? "В работе" : "Ждём Т2", demoState.t2Signed ? "" : demoState.t2Sent ? "sign-t2" : "send-t2")}
        ${docRow("ВГ", "Подтверждение выгрузки", "Ожидается после прибытия", "locked", "Позже")}
        ${docRow("₽", "Закрывающие документы", "УПД, акт и счёт", "locked", "Позже")}
      </div>
    </section>`;
}

function renderDemo() {
  const content = $("[data-demo-content]");
  if (!content) return;
  const screens = { queue: queueScreen, trip: tripScreen, docs: docsScreen };
  content.innerHTML = (screens[demoState.screen] || queueScreen)();
  $$('[data-demo-screen]').forEach((button) => button.classList.toggle("active", button.dataset.demoScreen === demoState.screen));
  $$('[data-queue-count]').forEach((node) => { node.textContent = unresolvedCount(); });
}

function renderPhonePreview(role = "driver") {
  const screen = $("[data-phone-preview]");
  if (!screen) return;
  const previews = {
    driver: `
      <header class="mobile-ui-head"><small>РЕЙС TK-24031 · ${demoState.t2Signed ? "В ПУТИ" : "НА ПОГРУЗКЕ"}</small><h3>Москва → Казань</h3><p>Максим Орлов · М 547 КТ 799</p></header>
      <div class="mobile-ui-body">
        <section class="mobile-next"><small>СЛЕДУЮЩИЙ ШАГ</small><h4>${demoState.t2Signed ? "Доставить груз" : "Подтвердить приём груза"}</h4><p>${demoState.t2Signed ? "Ворота №4 · сообщить о прибытии за час." : "Проверьте груз и данные машины перед подписанием."}</p><div class="mobile-action">${demoState.t2Signed ? "Я на выгрузке →" : "Подписать титул Т2 →"}</div></section>
        <section class="mobile-card"><small>МАРШРУТ И КОНТАКТЫ</small><div class="mobile-row"><span>Погрузка</span><strong>Москва · выполнено</strong></div><div class="mobile-row"><span>Выгрузка</span><strong>Казань · 20:00</strong></div><div class="mobile-row"><span>Контакт</span><strong>+7 843 000-12-40</strong></div></section>
        <section class="mobile-card"><small>ДОКУМЕНТЫ</small><div class="mobile-row"><span>ЭТрН</span><strong>${demoState.t2Signed ? "Подписана" : "Ждёт Т2"}</strong></div><div class="mobile-row"><span>Проверка</span><strong>${demoState.t2Signed ? "QR доступен" : "QR формируется"}</strong></div></section>
      </div>`,
    client: `
      <header class="mobile-ui-head"><small>ВАША ПЕРЕВОЗКА · TK-24031</small><h3>${demoState.t2Signed ? "Груз в пути" : "Машина на погрузке"}</h3><p>${demoState.t2Signed ? "Расчётное прибытие сегодня в 18:40" : "Проверяем документы перед выездом"}</p></header>
      <div class="mobile-ui-body">
        <section class="mobile-next"><small>СТАТУС</small><h4>${demoState.t2Signed ? "Машина прошла Чебоксары" : "Ожидается подпись перевозчика"}</h4><p>${demoState.t2Signed ? "До точки выгрузки 152 км. Отклонений от плана нет." : "После подписи появится QR, и машина сможет начать рейс."}</p><div class="mobile-action">Связаться с логистом</div></section>
        <section class="mobile-card"><small>ГЛАВНОЕ</small><div class="mobile-row"><span>Стоимость</span><strong>148 000 ₽</strong></div><div class="mobile-row"><span>Документы</span><strong>${demoState.t2Signed ? "В порядке" : "1 подпись ожидается"}</strong></div><div class="mobile-row"><span>Выгрузка</span><strong>Казань · сегодня</strong></div></section>
        <section class="mobile-card"><small>ПОСЛЕ ДОСТАВКИ</small><h4>Закрывающие появятся здесь</h4><p>Не нужно запрашивать их в переписке.</p></section>
      </div>`,
    logist: `
      <header class="mobile-ui-head"><small>ОПЕРАЦИОННЫЙ ЦЕНТР</small><h3>${unresolvedCount()} задачи требуют реакции</h3><p>Остальные рейсы идут по плану</p></header>
      <div class="mobile-ui-body">
        <section class="mobile-next"><small>ПРИОРИТЕТ</small><h4>${demoState.t2Signed ? "QR готов водителю" : "Ждём подпись Т2"}</h4><p>TK-24031 · ООО «Вектор» · ${demoState.t2Signed ? "можно выпускать" : "блокирует QR-код"}</p><div class="mobile-action">${demoState.t2Signed ? "Открыть QR" : "Напомнить перевозчику"}</div></section>
        <section class="mobile-card"><small>ЕЩЁ СЕГОДНЯ</small><div class="mobile-row"><span>TK-24033</span><strong>${demoState.innFixed ? "Ошибка исправлена" : "Ошибка ИНН"}</strong></div><div class="mobile-row"><span>TK-24029</span><strong>${demoState.closingDone ? "Закрыто" : "Нет УПД"}</strong></div></section>
      </div>`
  };
  screen.innerHTML = previews[role] || previews.driver;
}

function updateDemo(action) {
  if (action === "fix-inn") {
    demoState.innFixed = true;
    showToast("ИНН исправлен. XML успешно прошёл проверку.");
  }
  if (action === "send-t2") {
    demoState.t2Sent = true;
    showToast("Титул Т2 отправлен перевозчику на подпись.");
  }
  if (action === "sign-t2") {
    demoState.t2Sent = true;
    demoState.t2Signed = true;
    showToast("Подпись получена. QR-код сформирован.");
  }
  if (action === "closing") {
    demoState.closingDone = true;
    showToast("Запрос отправлен. Задача поставлена перевозчику.");
  }
  if (action === "open-trip") demoState.screen = "trip";
  saveState();
  renderDemo();
  const activeRole = $("[data-role-preview].active")?.dataset.rolePreview || "driver";
  renderPhonePreview(activeRole);
}

document.addEventListener("click", (event) => {
  const scrollButton = event.target.closest("[data-scroll-demo]");
  if (scrollButton) scrollToDemo();

  const docRole = event.target.closest("[data-doc-role]");
  if (docRole) {
    $$('[data-doc-role]').forEach((button) => button.classList.toggle("active", button === docRole));
    renderDocumentRole(docRole.dataset.docRole);
  }

  const screenButton = event.target.closest("[data-demo-screen]");
  if (screenButton) {
    demoState.screen = screenButton.dataset.demoScreen;
    saveState();
    renderDemo();
  }

  const actionButton = event.target.closest("[data-demo-action]");
  if (actionButton && !actionButton.disabled) updateDemo(actionButton.dataset.demoAction);

  const roleButton = event.target.closest("[data-role-preview]");
  if (roleButton) {
    $$('[data-role-preview]').forEach((button) => button.classList.toggle("active", button === roleButton));
    renderPhonePreview(roleButton.dataset.rolePreview);
  }

  if (event.target.closest("[data-reset-demo]")) {
    demoState = { ...initialState };
    saveState();
    renderDemo();
    renderPhonePreview("driver");
    $$('[data-role-preview]').forEach((button, index) => button.classList.toggle("active", index === 0));
    showToast("Демо возвращено в исходное состояние.");
  }
});

$("[data-pilot-form]")?.addEventListener("submit", (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  demoState.pilot = {
    role: form.get("companyRole"),
    operator: form.get("operator"),
    pain: form.get("pain")
  };
  demoState.screen = "queue";
  saveState();
  renderDemo();
  showToast("Сценарий сохранён и добавлен в демо-очередь.");
  setTimeout(scrollToDemo, 250);
});

renderDocumentRole("forwarder");
renderDemo();
renderPhonePreview("driver");

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("./sw.js").catch(() => {}));
}
