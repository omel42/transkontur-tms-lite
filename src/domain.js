export const STATUSES = [
  { id: "new", label: "Новый", tone: "neutral" },
  { id: "planned", label: "Назначен", tone: "blue" },
  { id: "loading", label: "На погрузке", tone: "amber" },
  { id: "in_transit", label: "В пути", tone: "violet" },
  { id: "delivered", label: "Доставлен", tone: "green" },
  { id: "closed", label: "Закрыт", tone: "dark" },
  { id: "issue", label: "Проблема", tone: "red" }
];

export const NEXT_STATUS = {
  new: "planned",
  planned: "loading",
  loading: "in_transit",
  in_transit: "delivered",
  delivered: "closed",
  closed: "closed",
  issue: "in_transit"
};

export const STATUS_LABEL = Object.fromEntries(STATUSES.map((status) => [status.id, status.label]));

export function money(value = 0) {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    maximumFractionDigits: 0
  }).format(Number(value) || 0);
}

export function shortDate(value) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("ru-RU", { day: "2-digit", month: "short" }).format(new Date(value));
}

export function dateTime(value) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("ru-RU", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit"
  }).format(new Date(value));
}

export function tripMargin(trip) {
  const cost = Number(trip.actualCost || trip.plannedCost || 0);
  return Number(trip.price || 0) - cost;
}

export function marginPercent(trip) {
  const price = Number(trip.price || 0);
  return price ? Math.round((tripMargin(trip) / price) * 100) : 0;
}

export function calculateMetrics(trips) {
  const activeStatuses = new Set(["planned", "loading", "in_transit", "issue"]);
  const activeTrips = trips.filter((trip) => activeStatuses.has(trip.status));
  const completedTrips = trips.filter((trip) => ["delivered", "closed"].includes(trip.status));
  const basis = completedTrips.length ? completedTrips : trips;
  const revenue = basis.reduce((sum, trip) => sum + Number(trip.price || 0), 0);
  const margin = basis.reduce((sum, trip) => sum + tripMargin(trip), 0);
  const docsIssues = trips.filter((trip) => {
    const needsWaybill = ["loading", "in_transit", "delivered", "closed"].includes(trip.status);
    const needsClosing = ["delivered", "closed"].includes(trip.status);
    return !trip.docs?.request || (needsWaybill && !trip.docs?.waybill) || (needsClosing && !trip.docs?.closing);
  }).length;
  return {
    active: activeTrips.length,
    revenue,
    margin,
    marginPercent: revenue ? Math.round((margin / revenue) * 100) : 0,
    docsIssues
  };
}

export function filterTrips(trips, { query = "", status = "all" } = {}) {
  const needle = query.trim().toLocaleLowerCase("ru");
  return trips.filter((trip) => {
    const matchesStatus = status === "all" || trip.status === status;
    const haystack = [trip.number, trip.client, trip.from, trip.to, trip.cargo]
      .join(" ")
      .toLocaleLowerCase("ru");
    return matchesStatus && (!needle || haystack.includes(needle));
  });
}

export function createTrip(input, state, now = new Date()) {
  const numericIds = state.trips
    .map((trip) => Number(String(trip.number).replace(/\D/g, "")))
    .filter(Number.isFinite);
  const nextNumber = Math.max(1030, ...numericIds) + 1;
  const id = globalThis.crypto?.randomUUID?.() || `trip-${Date.now()}`;
  const status = input.driverId && input.vehicleId ? "planned" : "new";
  const isoNow = now.toISOString();
  return {
    id,
    number: `Р-${nextNumber}`,
    client: input.client.trim(),
    contact: input.contact?.trim() || "",
    phone: input.phone?.trim() || "",
    from: input.from.trim(),
    to: input.to.trim(),
    cargo: input.cargo.trim(),
    weight: Number(input.weight || 0),
    pickupAt: input.pickupAt,
    deliveryAt: input.deliveryAt,
    price: Number(input.price || 0),
    plannedCost: Number(input.plannedCost || 0),
    actualCost: 0,
    driverId: input.driverId || "",
    vehicleId: input.vehicleId || "",
    status,
    comment: input.comment?.trim() || "",
    createdAt: isoNow,
    docs: { request: false, waybill: false, closing: false },
    events: [
      { at: isoNow, status: "new", note: "Заявка создана" },
      ...(status === "planned" ? [{ at: isoNow, status: "planned", note: "Экипаж назначен" }] : [])
    ]
  };
}

export function updateTripStatus(trip, status, now = new Date()) {
  if (!STATUS_LABEL[status] || status === trip.status) return trip;
  return {
    ...trip,
    status,
    events: [
      ...(trip.events || []),
      { at: now.toISOString(), status, note: `Статус изменён: ${STATUS_LABEL[status]}` }
    ]
  };
}

export function completionPercent(status) {
  const map = { new: 8, planned: 24, loading: 42, in_transit: 68, issue: 68, delivered: 90, closed: 100 };
  return map[status] || 0;
}

export function escapeCsv(value) {
  const text = String(value ?? "");
  return /[;"\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

export function tripsToCsv(trips) {
  const headers = ["Номер", "Клиент", "Откуда", "Куда", "Груз", "Статус", "Выручка", "Затраты", "Маржа"];
  const rows = trips.map((trip) => [
    trip.number,
    trip.client,
    trip.from,
    trip.to,
    trip.cargo,
    STATUS_LABEL[trip.status] || trip.status,
    trip.price,
    trip.actualCost || trip.plannedCost,
    tripMargin(trip)
  ]);
  return [headers, ...rows].map((row) => row.map(escapeCsv).join(";")).join("\n");
}
