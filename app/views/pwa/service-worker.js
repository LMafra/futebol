// Installable app (TICKET-0101). Pages always come from the network (scores and lances are live); when a page
// cannot load, the precached /offline.html answers instead. Nothing else is cached.
const CACHE = "craquefy-offline-v1"
const OFFLINE_URL = "/offline.html"
const PRECACHE = [OFFLINE_URL, "/icon.svg"]

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(PRECACHE)).then(() => self.skipWaiting()))
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

self.addEventListener("fetch", (event) => {
  const { request } = event
  if (request.method !== "GET") return

  if (request.mode === "navigate") {
    event.respondWith(fetch(request).catch(() => caches.match(OFFLINE_URL)))
  } else if (PRECACHE.includes(new URL(request.url).pathname)) {
    event.respondWith(caches.match(request).then((cached) => cached || fetch(request)))
  }
})
