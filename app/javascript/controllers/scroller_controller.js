import { Controller } from "@hotwired/stimulus"

// Previous/next buttons for a horizontal list, one visible width per click. The buttons only show when the list
// overflows; without JS the list still scrolls by touch, trackpad or shift + wheel.
export default class extends Controller {
  static targets = ["list", "nav", "previous", "next"]

  connect() {
    if (!this.hasListTarget) return

    this.observer = new ResizeObserver(() => this.update())
    this.observer.observe(this.listTarget)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  previous() {
    this.scroll(-1)
  }

  next() {
    this.scroll(1)
  }

  scroll(direction) {
    const smooth = !window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.listTarget.scrollBy({ left: direction * this.listTarget.clientWidth, behavior: smooth ? "smooth" : "auto" })
  }

  update() {
    const list = this.listTarget
    const end = list.scrollWidth - list.clientWidth
    this.navTarget.hidden = end <= 1
    this.previousTarget.disabled = list.scrollLeft <= 1
    this.nextTarget.disabled = list.scrollLeft >= end - 1
  }
}
