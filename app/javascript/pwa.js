// Installable app (TICKET-0101): the service worker only serves /offline.html when a page cannot load.
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("/service-worker.js", { scope: "/" }).catch(() => {})
  })
}
