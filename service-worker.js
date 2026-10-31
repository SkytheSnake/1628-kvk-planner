const CACHE_NAME = "kvk-planner-1628-planner-auth-1";
const CORE_ASSETS = [
  "./",
  "./index.html",
  "./admin.html",
  "./style.css",
  "./app.js",
  "./admin.js",
  "./config.js",
  "./backend.js",
  "./calculator.html",
  "./calculator.js",
  "./calculator.css",
  "./calculator-engine.js",
  "./building-data.js",
  "./translations.js",
  "./manifest.webmanifest",
  "./favicon.ico",
  "./favicon-32.png",
  "./apple-touch-icon.png",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-maskable-512.png"
];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(CORE_ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", event => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  const isLocalAppAsset = url.origin === self.location.origin;
  const networkFirst =
    request.mode === "navigate" ||
    request.destination === "document" ||
    (isLocalAppAsset && /\.(?:js|css|html)$/.test(url.pathname));

  if (networkFirst) {
    event.respondWith(
      fetch(request).then(response => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(request, copy));
        return response;
      }).catch(() => caches.match(request).then(r => r || (request.mode === "navigate" ? caches.match("./index.html") : undefined)))
    );
    return;
  }

  event.respondWith(
    caches.match(request).then(cached => {
      return cached || fetch(request).then(response => {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(request, copy));
        return response;
      });
    })
  );
});
