import { Controller } from "@hotwired/stimulus"

// Ui::CollectionComponent. Views and sorting are plain links (?view=, ?sort=&dir=), so the listing works without
// JS; this controller remembers the chosen view per listing and drives the bulk selection bar.
export default class extends Controller {
  static targets = ["item", "all", "bar", "count"]
  static values = { key: String, view: String, views: Array }

  connect() {
    this.restoreView()
    this.count()
  }

  // A listing opened without ?view= goes back to the view last chosen on it.
  restoreView() {
    if (this.viewsValue.length < 2) return

    const url = new URL(window.location.href)
    if (url.searchParams.has("view")) return this.remember(this.viewValue)

    const stored = this.stored()
    if (!stored || stored === this.viewValue || !this.viewsValue.includes(stored)) return

    url.searchParams.set("view", stored)
    window.Turbo ? window.Turbo.visit(url.toString(), { action: "replace" }) : window.location.replace(url)
  }

  choose({ params: { view } }) {
    this.remember(view)
  }

  count() {
    const checked = this.itemTargets.filter((box) => box.checked).length
    if (this.hasCountTarget) this.countTarget.textContent = checked
    if (this.hasBarTarget) this.barTarget.hidden = checked === 0
    if (!this.hasAllTarget) return

    this.allTarget.checked = checked > 0 && checked === this.itemTargets.length
    this.allTarget.indeterminate = checked > 0 && checked < this.itemTargets.length
  }

  toggleAll() {
    this.itemTargets.forEach((box) => { box.checked = this.allTarget.checked })
    this.count()
  }

  confirm(event) {
    const message = event.params.confirm
    if (message && !window.confirm(message)) event.preventDefault()
  }

  remember(view) {
    try { localStorage.setItem(this.storageKey, view) } catch { /* storage blocked: the URL still holds the view */ }
  }

  stored() {
    try { return localStorage.getItem(this.storageKey) } catch { return null }
  }

  get storageKey() {
    return `collection:${this.keyValue}:view`
  }
}
