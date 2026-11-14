import { Controller } from "@hotwired/stimulus"

// Endless horizontal list. When the items overflow, copies of them go before (one set) and after (two sets, so a
// "next" from anywhere in the originals still has room), hidden from assistive tech and the tab order. Once a
// scroll settles outside the originals, the list jumps by one set to the same card among them, so it never reaches
// an end. Previous/next move one card. Without JS the list is a plain horizontal scroll.
//
// With an autoplay value (ms) it advances one card on that interval while the items overflow. Pointer or focus
// inside holds it; a touch or the toggle button stops it until the button resumes it. "Reduce motion" turns it off.
export default class extends Controller {
  static targets = ["list", "nav", "toggle"]
  static values = { autoplay: Number }

  connect() {
    if (!this.hasListTarget) return

    this.observer = new ResizeObserver(() => {
      if (this.listTarget.clientWidth === this.width) return

      this.width = this.listTarget.clientWidth
      this.layout()
    })
    this.observer.observe(this.listTarget)
  }

  disconnect() {
    this.observer?.disconnect()
    clearTimeout(this.timer)
    clearInterval(this.interval)
    if (this.hasListTarget) this.removeCopies()
  }

  previous() {
    this.scroll(-1)
    this.play()
  }

  next() {
    this.scroll(1)
    this.play()
  }

  // Wraps only after the scroll settles (smooth, snapped or touch momentum), never mid-gesture.
  scrolled() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.wrap(), 150)
  }

  hold() {
    this.held = true
    this.play()
  }

  // Runs after focus moves, so leaving one card for another inside keeps it held.
  release() {
    setTimeout(() => {
      this.held = this.element.matches(":hover") || this.element.contains(document.activeElement)
      this.play()
    })
  }

  stop() {
    this.stopped = true
    this.play()
  }

  toggle() {
    this.stopped = !this.stopped
    this.play()
  }

  play() {
    clearInterval(this.interval)
    if (this.hasToggleTarget) this.toggleTarget.textContent = this.stopped ? "Continuar" : "Pausar"
    if (!this.autoplays || this.stopped || this.held) return

    this.interval = setInterval(() => this.scroll(1), this.autoplayValue)
  }

  scroll(direction) {
    this.wrap()
    const step = this.listTarget.firstElementChild.offsetWidth
    this.listTarget.scrollBy({ left: direction * step, behavior: this.reducedMotion ? "auto" : "smooth" })
  }

  get reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  layout() {
    const list = this.listTarget
    this.removeCopies()
    this.setWidth = 0
    const overflows = list.scrollWidth > list.clientWidth + 1
    if (this.hasNavTarget) this.navTarget.hidden = !overflows
    this.autoplays = overflows && this.autoplayValue > 0 && !this.reducedMotion
    if (this.hasToggleTarget) this.toggleTarget.hidden = !this.autoplays
    this.play()
    if (!overflows) return

    const items = [...list.children]
    list.prepend(...this.copies(items))
    list.append(...this.copies(items), ...this.copies(items))
    this.setWidth = items[0].offsetLeft - list.firstElementChild.offsetLeft
    list.scrollLeft = this.setWidth
  }

  wrap() {
    if (!this.setWidth) return

    const list = this.listTarget
    if (list.scrollLeft < this.setWidth) list.scrollLeft += this.setWidth
    else if (list.scrollLeft >= 2 * this.setWidth) list.scrollLeft -= this.setWidth
  }

  copies(items) {
    return items.map((item) => {
      const copy = item.cloneNode(true)
      copy.dataset.scrollerCopy = ""
      copy.removeAttribute("data-role")
      copy.setAttribute("aria-hidden", "true")
      copy.querySelectorAll("a, button").forEach((element) => { element.tabIndex = -1 })
      return copy
    })
  }

  removeCopies() {
    this.listTarget.querySelectorAll("[data-scroller-copy]").forEach((copy) => copy.remove())
  }
}
