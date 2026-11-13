import { Controller } from "@hotwired/stimulus"

// "Sobre esta tela" (PageIntroHelper): a <details> open by default; once the user closes it, it stays closed on
// that screen. Without JavaScript it is simply open.
export default class extends Controller {
  static values = { key: String }

  connect() {
    if (this.read() === "closed") this.element.open = false
  }

  remember() {
    try { localStorage.setItem(this.storageKey, this.element.open ? "open" : "closed") } catch { /* storage blocked */ }
  }

  read() {
    try { return localStorage.getItem(this.storageKey) } catch { return null }
  }

  get storageKey() {
    return `page-intro:${this.keyValue}`
  }
}
