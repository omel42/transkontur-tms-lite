const CACHE = "transkontur-v5";
const ASSETS = [
  "./",
  "./index.html",
  "./styles.css?v=5",
  "./app.css?v=5",
  "./responsive.css?v=5",
  "./fix.css?v=5",
  "./src/app.js?v=5",
  "./src/domain.js?v=5",
  "./src/seed.js?v=5",
  "./assets/logo-mark.svg",
  "./assets/hero-logistics.jpg",
  "./icon.svg"
];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)))));
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const copy = response.clone();
        caches.open(CACHE).then((cache) => cache.put(event.request, copy));
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
