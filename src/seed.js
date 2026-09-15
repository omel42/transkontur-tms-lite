const day = 24 * 60 * 60 * 1000;
const now = new Date();

const at = (offsetDays, hour, minute = 0) => {
  const value = new Date(now.getTime() + offsetDays * day);
  value.setHours(hour, minute, 0, 0);
  return value.toISOString();
};

export const seedState = {
  company: {
    name: "ООО «ТрансКонтур Логистика»",
    shortName: "ТрансКонтур",
    manager: "Алексей",
    phone: "+7 495 120-42-42",
    email: "hello@transkontur.ru"
  },
  leads: [
    {
      id: "l1007", number: "Л-1007", company: "НордПром", contact: "Екатерина Морозова",
      phone: "+7 903 721-18-06", from: "Москва", to: "Екатеринбург",
      cargo: "Промышленное оборудование", weight: 18, pickupAt: at(2, 10), status: "new",
      source: "Сайт", clientRate: 238000, carrierRate: 184000,
      nextAction: "Уточнить габариты до 18:00", createdAt: at(0, 11, 18),
      note: "Боковая загрузка, нужна обрешётка. Клиент ждёт ответ сегодня."
    },
    {
      id: "l1006", number: "Л-1006", company: "СтройВектор", contact: "Сергей Павлов",
      phone: "+7 926 744-09-31", from: "Подольск", to: "Нижний Новгород",
      cargo: "Сухие смеси на палетах", weight: 20, pickupAt: at(1, 8), status: "contacted",
      source: "Телефон", clientRate: 112000, carrierRate: 84000,
      nextAction: "Перезвонить в 16:30", createdAt: at(0, 9, 42),
      note: "Регулярно 2–3 машины в неделю, оплата с НДС."
    },
    {
      id: "l1005", number: "Л-1005", company: "Вкус Севера", contact: "Марина Волкова",
      phone: "+7 901 944-10-56", from: "Тверь", to: "Санкт-Петербург",
      cargo: "Замороженные продукты", weight: 15, pickupAt: at(2, 7), status: "quote",
      source: "Рекомендация", clientRate: 129000, carrierRate: 91000,
      nextAction: "Предложение действительно до 19:00", createdAt: at(-1, 14, 5),
      note: "Температурный режим −18 °C, нужна распечатка термографа."
    },
    {
      id: "l1004", number: "Л-1004", company: "Линия Дома", contact: "Владислав",
      phone: "+7 915 118-30-70", from: "Калуга", to: "Рязань",
      cargo: "Корпусная мебель", weight: 8, pickupAt: at(3, 9), status: "agreed",
      source: "Повторный клиент", clientRate: 78000, carrierRate: 57000,
      nextAction: "Назначить машину", createdAt: at(-2, 12),
      note: "Нужны ремни и чистый кузов. Выгрузка по записи."
    },
    {
      id: "l1003", number: "Л-1003", company: "Альфа Кабель", contact: "Дмитрий Орлов",
      phone: "+7 916 330-04-17", from: "Москва", to: "Самара",
      cargo: "Кабельные барабаны", weight: 19, pickupAt: at(4, 13), status: "quote",
      source: "Телефон", clientRate: 176000, carrierRate: 139000,
      nextAction: "Ждём реквизиты", createdAt: at(-2, 10),
      note: "Верхняя загрузка, коники предоставляет отправитель."
    }
  ],
  clients: [
    { id: "c1", name: "Спектр Маркет", contact: "Ольга Громова", phone: "+7 903 522-18-14", email: "logist@spektr.example", orders: 14, revenue: 1926000, debt: 148000, lastRoute: "Москва → Казань", status: "active" },
    { id: "c2", name: "СтройВектор", contact: "Сергей Павлов", phone: "+7 926 744-09-31", email: "s.pavlov@vector.example", orders: 8, revenue: 812000, debt: 0, lastRoute: "Подольск → Ярославль", status: "active" },
    { id: "c3", name: "Вкус Севера", contact: "Марина Волкова", phone: "+7 901 944-10-56", email: "supply@vkus.example", orders: 6, revenue: 756000, debt: 126000, lastRoute: "Тверь → Санкт-Петербург", status: "active" },
    { id: "c4", name: "Линия Дома", contact: "Владислав Котов", phone: "+7 915 118-30-70", email: "log@linedom.example", orders: 4, revenue: 304000, debt: 76000, lastRoute: "Калуга → Рязань", status: "warm" }
  ],
  carriers: [
    { id: "cr1", name: "ИП Орлов М.А.", inn: "503812904166", rating: 4.9, completed: 37, onTime: 96, type: "Тенты 20 т", phone: "+7 999 241-50-18", status: "available", docsUntil: at(82, 0) },
    { id: "cr2", name: "ООО «ФростЛайн»", inn: "7814783112", rating: 4.8, completed: 24, onTime: 92, type: "Рефрижераторы", phone: "+7 921 605-20-17", status: "on_trip", docsUntil: at(164, 0) },
    { id: "cr3", name: "ИП Галиев А.Р.", inn: "165022740981", rating: 4.7, completed: 18, onTime: 94, type: "Тенты 20 т", phone: "+7 926 512-94-33", status: "available", docsUntil: at(28, 0) },
    { id: "cr4", name: "ООО «Вектор Транс»", inn: "7726482901", rating: 4.6, completed: 12, onTime: 88, type: "Фургоны до 5 т", phone: "+7 985 755-12-42", status: "review", docsUntil: at(11, 0) }
  ],
  drivers: [
    { id: "d1", name: "Максим Орлов", phone: "+7 999 241-50-18", status: "on_trip", license: "77 21 •••921" },
    { id: "d2", name: "Иван Соколов", phone: "+7 916 830-41-27", status: "available", license: "50 19 •••488" },
    { id: "d3", name: "Роман Ким", phone: "+7 985 166-38-90", status: "on_trip", license: "77 23 •••109" },
    { id: "d4", name: "Артур Галиев", phone: "+7 926 512-94-33", status: "rest", license: "16 18 •••412" }
  ],
  vehicles: [
    { id: "v1", plate: "М 547 КТ 799", model: "КАМАЗ 54901", type: "Тент 20 т", status: "on_trip" },
    { id: "v2", plate: "Е 901 ХА 50", model: "Volvo FH", type: "Рефрижератор 20 т", status: "available" },
    { id: "v3", plate: "Т 318 МС 77", model: "Sitrak C7H", type: "Тент 20 т", status: "on_trip" },
    { id: "v4", plate: "К 112 ОВ 799", model: "Газель Next", type: "Фургон 1.5 т", status: "service" }
  ],
  trips: [
    {
      id: "t1031", number: "TK-24031", clientId: "c1", client: "Спектр Маркет", contact: "Ольга",
      phone: "+7 903 522-18-14", from: "Москва", to: "Казань", distance: 824,
      cargo: "Бытовая техника", weight: 18, pickupAt: at(-1, 9), deliveryAt: at(0, 20), eta: at(0, 18, 40),
      price: 148000, plannedCost: 104000, actualCost: 108500,
      driverId: "d1", vehicleId: "v1", carrierId: "cr1", status: "in_transit", paymentStatus: "invoice",
      comment: "Выгрузка через ворота №4. Позвонить за час.", createdAt: at(-3, 12),
      docs: { request: true, waybill: true, closing: false, invoice: true },
      checkpoints: [
        { city: "Москва", label: "Погрузка", at: at(-1, 9), done: true },
        { city: "Владимир", label: "Контрольная точка", at: at(-1, 17), done: true },
        { city: "Казань", label: "Выгрузка", at: at(0, 20), done: false }
      ],
      events: [
        { at: at(-3, 12), status: "new", note: "Заказ подтверждён клиентом" },
        { at: at(-2, 16), status: "planned", note: "Назначены перевозчик и водитель" },
        { at: at(-1, 9), status: "loading", note: "Машина прибыла на погрузку" },
        { at: at(-1, 12), status: "in_transit", note: "Груз принят, водитель выехал" },
        { at: at(0, 11), status: "in_transit", note: "Контрольная точка пройдена без отклонений" }
      ]
    },
    {
      id: "t1032", number: "TK-24032", clientId: "c2", client: "СтройВектор", contact: "Сергей",
      phone: "+7 926 744-09-31", from: "Подольск", to: "Ярославль", distance: 312,
      cargo: "Строительные смеси", weight: 20, pickupAt: at(0, 14), deliveryAt: at(1, 10), eta: at(1, 10, 30),
      price: 92000, plannedCost: 69000, actualCost: 0,
      driverId: "d3", vehicleId: "v3", carrierId: "cr3", status: "loading", paymentStatus: "not_invoiced",
      comment: "Обязательны ремни, фото крепления до выезда.", createdAt: at(-2, 10),
      docs: { request: true, waybill: false, closing: false, invoice: false },
      checkpoints: [
        { city: "Подольск", label: "Погрузка", at: at(0, 14), done: true },
        { city: "Ярославль", label: "Выгрузка", at: at(1, 10), done: false }
      ],
      events: [
        { at: at(-2, 10), status: "new", note: "Заказ создан из расчёта" },
        { at: at(-1, 11), status: "planned", note: "Назначен перевозчик" },
        { at: at(0, 14), status: "loading", note: "Водитель отметил прибытие" }
      ]
    },
    {
      id: "t1033", number: "TK-24033", clientId: "c3", client: "Вкус Севера", contact: "Марина",
      phone: "+7 901 944-10-56", from: "Тверь", to: "Санкт-Петербург", distance: 534,
      cargo: "Замороженные продукты", weight: 15, pickupAt: at(1, 7), deliveryAt: at(1, 19), eta: at(1, 18, 20),
      price: 126000, plannedCost: 88000, actualCost: 0,
      driverId: "d2", vehicleId: "v2", carrierId: "cr2", status: "planned", paymentStatus: "not_invoiced",
      comment: "Температурный режим −18 °C.", createdAt: at(-1, 13),
      docs: { request: true, waybill: false, closing: false, invoice: false },
      checkpoints: [
        { city: "Тверь", label: "Погрузка", at: at(1, 7), done: false },
        { city: "Санкт-Петербург", label: "Выгрузка", at: at(1, 19), done: false }
      ],
      events: [
        { at: at(-1, 13), status: "new", note: "Заказ подтверждён" },
        { at: at(-1, 14), status: "planned", note: "Экипаж назначен" }
      ]
    },
    {
      id: "t1030", number: "TK-24030", clientId: "c1", client: "Спектр Маркет", contact: "Ольга",
      phone: "+7 903 522-18-14", from: "Санкт-Петербург", to: "Москва", distance: 708,
      cargo: "Упаковка", weight: 12, pickupAt: at(-4, 9), deliveryAt: at(-3, 17), eta: at(-3, 16, 45),
      price: 112000, plannedCost: 78000, actualCost: 80600,
      driverId: "d2", vehicleId: "v2", carrierId: "cr2", status: "closed", paymentStatus: "paid",
      comment: "", createdAt: at(-6, 11), docs: { request: true, waybill: true, closing: true, invoice: true },
      checkpoints: [],
      events: [
        { at: at(-6, 11), status: "new", note: "Заказ создан" },
        { at: at(-3, 17), status: "delivered", note: "Груз принят получателем" },
        { at: at(-2, 12), status: "closed", note: "Документы получены, рейс закрыт" }
      ]
    },
    {
      id: "t1029", number: "TK-24029", clientId: "c4", client: "Линия Дома", contact: "Владислав",
      phone: "+7 915 118-30-70", from: "Калуга", to: "Рязань", distance: 218,
      cargo: "Мебель", weight: 8, pickupAt: at(-5, 8), deliveryAt: at(-4, 15), eta: at(-4, 14, 32),
      price: 76000, plannedCost: 55000, actualCost: 58600,
      driverId: "d4", vehicleId: "v4", carrierId: "cr4", status: "delivered", paymentStatus: "overdue",
      comment: "Ожидаем оригинал транспортной накладной.", createdAt: at(-7, 10),
      docs: { request: true, waybill: true, closing: false, invoice: true }, checkpoints: [],
      events: [
        { at: at(-7, 10), status: "new", note: "Заказ создан" },
        { at: at(-4, 15), status: "delivered", note: "Груз принят получателем" }
      ]
    }
  ]
};
