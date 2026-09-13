import test from "node:test";
import assert from "node:assert/strict";
import {
  calculateMetrics,
  createTrip,
  filterTrips,
  marginPercent,
  tripMargin,
  tripsToCsv,
  updateTripStatus
} from "../src/domain.js";

const baseTrip = {
  id: "one",
  number: "Р-1031",
  client: "Спектр",
  from: "Москва",
  to: "Казань",
  cargo: "Техника",
  price: 150000,
  plannedCost: 100000,
  actualCost: 110000,
  status: "delivered",
  docs: { request: true, waybill: true, closing: false },
  events: []
};

test("calculates trip margin from actual cost first", () => {
  assert.equal(tripMargin(baseTrip), 40000);
  assert.equal(marginPercent(baseTrip), 27);
});

test("calculates operational metrics", () => {
  const metrics = calculateMetrics([
    baseTrip,
    { ...baseTrip, id: "two", status: "in_transit", price: 80000, actualCost: 0, plannedCost: 60000, docs: { request: false } }
  ]);
  assert.equal(metrics.active, 1);
  assert.equal(metrics.revenue, 150000);
  assert.equal(metrics.margin, 40000);
  assert.equal(metrics.docsIssues, 2);
});

test("filters by status and Russian text", () => {
  const trips = [baseTrip, { ...baseTrip, id: "two", client: "Арсенал", status: "planned" }];
  assert.deepEqual(filterTrips(trips, { query: "казань", status: "delivered" }).map((trip) => trip.id), ["one"]);
  assert.deepEqual(filterTrips(trips, { query: "арсенал" }).map((trip) => trip.id), ["two"]);
});

test("creates a sequential assigned trip", () => {
  const created = createTrip({
    client: "Новый клиент",
    from: "Тула",
    to: "Москва",
    cargo: "Тара",
    pickupAt: "2026-09-14T10:00",
    deliveryAt: "2026-09-14T18:00",
    price: "70000",
    plannedCost: "50000",
    driverId: "d1",
    vehicleId: "v1"
  }, { trips: [baseTrip] }, new Date("2026-09-13T12:00:00Z"));
  assert.equal(created.number, "Р-1032");
  assert.equal(created.status, "planned");
  assert.equal(created.events.length, 2);
});

test("adds an audit event when status changes", () => {
  const updated = updateTripStatus(baseTrip, "closed", new Date("2026-09-13T14:00:00Z"));
  assert.equal(updated.status, "closed");
  assert.equal(updated.events.at(-1).note, "Статус изменён: Закрыт");
});

test("exports a semicolon-separated CSV", () => {
  const csv = tripsToCsv([{ ...baseTrip, cargo: "Коробки; палеты" }]);
  assert.match(csv, /Номер;Клиент/);
  assert.match(csv, /"Коробки; палеты"/);
  assert.match(csv, /40000/);
});
