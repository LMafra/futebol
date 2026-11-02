import { Controller } from "@hotwired/stimulus"

// Proximity vertical scroll snap while this element is on the page. The snap type must sit on <html> (the
// viewport's scroller), whose attributes Turbo keeps across visits, so it is added on connect and removed on
// disconnect instead of being rendered by the server.
export default class extends Controller {
  connect() {
    document.documentElement.classList.add("snap-y", "snap-proximity")
  }

  disconnect() {
    document.documentElement.classList.remove("snap-y", "snap-proximity")
  }
}
