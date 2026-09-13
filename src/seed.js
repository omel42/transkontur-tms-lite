const day = 24 * 60 * 60 * 1000;
const now = new Date();
const at = (offsetDays, hour) => {
  const value = new Date(now.getTime() + offsetDays * day);
  value.setHours(hour, 0, 0, 0);
  return value.toISOString();
};

export const seedState = {
  company: { name: "ООО «СеверТранс»", manager: "Алексей" },
  drivers: [
    { id: "d1", name: "Максим Орлов", phone: "+7 999 241-50-18", status: "on_trip", license: "77 21 843921" },
    { id: "d2", name: "Иван Соколов", phone: "+7 916 830-41-27", status: "available", license: "50 19 301488" },
    { id: "d3", name: "Роман Ким", phone: "+7 985 166-38-90", status: "on_trip", license: "77 23 625109" },
    { id: "d4", name: "Артур Галиев", phone: "+7 926 512-94-33", status: "rest", license: "16 18 784412" }
  ],
  vehicles: [
    { id: "v1", plate: "М 547 КТ 799", model: "КАМАЗ 54901", type: "Тент 20 т", status: "on_trip" },
    { id: "v2", plate: "Е 901 ХА 50", model: "Volvo FH", type: "Рефрижератор 20 т", status: "available" },
    { id: "v3", plate: "Т 318 МС 77", model: "Sitrak C7H", type: "Тент 20 т", status: "on_trip" },
    { id: "v4", plate: "К 112 ОВ 799", model: "Газель Next", type: "Фургон 1.5 т", status: "service" }
  ],
  trips: [
    {
      id: "t1031",
      number: "Р-1031",
      client: "Спектр Маркет",
      contact: "Ольга",
      phone: "+7 903 522-18-14",
      from: "Москва",
      to: "Казань",
      cargo: "Бытовая техника",
      weight: 18,
      pickupAt: at(-1, 9),
      deliveryAt: at(0, 18),
      price: 148000,
      plannedCost: 104000,
      actualCost: 108500,
      driverId: "d1",
      vehicleId: "v1",
      status: "in_transit",
      comment: "Выгрузка через ворота №4. Позвонить за час.",
      createdAt: at(-3, 12),
      docs: { request: true, waybill: true, closing: false },
      events: [
        { at: at(-3, 12), status: "new", note: "Заявка создана" },
        { at: at(-2, 16), status: "planned", note: "Назначен Максим Орлов" },
        { at: at(-1, 9), status: "loading", note: "Машина на погрузке" },
        { at: at(-1, 12), status: "in_transit", note: "Выехал с погрузки" }
      ]
    },
    {
      id: "t1032",
      number: "Р-1032",
      client: "Арсенал Строй",
      contact: "Сергей",
      phone: "+7 925 777-04-92",
      from: "Подольск",
      to: "Ярославль",
      cargo: "Строительные смеси",
      weight: 20,
      pickupAt: at(0, 14),
      deliveryAt: at(1, 10),
      price: 92000,
      plannedCost: 69000,
      actualCost: 0,
      driverId: "d3",
      vehicleId: "v3",
      status: "loading",
      comment: "Обязательны ремни, фото крепления до выезда.",
      createdAt: at(-2, 10),
      docs: { request: true, waybill: false, closing: false },
      events: [
        { at: at(-2, 10), status: "new", note: "Заявка создана" },
        { at: at(-1, 11), status: "planned", note: "Назначен Роман Ким" },
        { at: at(0, 14), status: "loading", note: "Прибыл на склад" }
      ]
    },
    {
      id: "t1033",
      number: "Р-1033",
      client: "Вкус Севера",
      contact: "Марина",
      phone: "+7 901 944-10-56",
      from: "Тверь",
      to: "Санкт-Петербург",
      cargo: "Замороженные продукты",
      weight: 15,
      pickupAt: at(1, 7),
      deliveryAt: at(1, 19),
      price: 126000,
      plannedCost: 88000,
      actualCost: 0,
      driverId: "d2",
      vehicleId: "v2",
      status: "planned",
      comment: "Температурный режим −18 °C.",
      createdAt: at(-1, 13),
      docs: { request: true, waybill: false, closing: false },
      events: [
        { at: at(-1, 13), status: "new", note: "Заявка создана" },
        { at: at(-1, 14), status: "planned", note: "Назначен Иван Соколов" }
      ]
    },
    {
      id: "t1030",
      number: "Р-1030",
      client: "Нева Трейд",
      contact: "Антон",
      phone: "+7 911 730-20-11",
      from: "Санкт-Петербург",
      to: "Москва",
      cargo: "Упаковка",
      weight: 12,
      pickupAt: at(-4, 9),
      deliveryAt: at(-3, 17),
      price: 112000,
      plannedCost: 78000,
      actualCost: 80600,
      driverId: "d2",
      vehicleId: "v2",
      status: "closed",
      comment: "",
      createdAt: at(-6, 11),
      docs: { request: true, waybill: true, closing: true },
      events: [
        { at: at(-6, 11), status: "new", note: "Заявка создана" },
        { at: at(-3, 17), status: "delivered", note: "Груз доставлен" },
        { at: at(-2, 12), status: "closed", note: "Документы получены, рейс закрыт" }
      ]
    },
    {
      id: "t1029",
      number: "Р-1029",
      client: "Линия Дома",
      contact: "Владислав",
      phone: "+7 915 118-30-70",
      from: "Калуга",
      to: "Рязань",
      cargo: "Мебель",
      weight: 8,
      pickupAt: at(-5, 8),
      deliveryAt: at(-4, 15),
      price: 76000,
      plannedCost: 55000,
      actualCost: 58600,
      driverId: "d4",
      vehicleId: "v4",
      status: "delivered",
      comment: "Ожидаем оригинал ТН.",
      createdAt: at(-7, 10),
      docs: { request: true, waybill: true, closing: false },
      events: [
        { at: at(-7, 10), status: "new", note: "Заявка создана" },
        { at: at(-4, 15), status: "delivered", note: "Груз принят получателем" }
      ]
    }
  ]
};
