import { Controller } from "@hotwired/stimulus"

// Suggests names for an ActiveAdmin filter field through a native <datalist>, fed by GET <index>/autocomplete?q=.
export default class extends Controller {
  static values = { minLength: { type: Number, default: 2 }, delay: { type: Number, default: 200 } }

  connect() {
    this.list = document.createElement("datalist")
    this.list.id = `${this.element.id || "name"}-suggestions`
    this.element.after(this.list)
    this.element.setAttribute("list", this.list.id)
    this.onInput = () => this.schedule()
    this.element.addEventListener("input", this.onInput)
  }

  disconnect() {
    this.element.removeEventListener("input", this.onInput)
    clearTimeout(this.timer)
    this.list.remove()
  }

  schedule() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.suggest(), this.delayValue)
  }

  async suggest() {
    const term = this.element.value.trim()
    if (term.length < this.minLengthValue) return this.list.replaceChildren()

    const url = new URL(`${this.element.form.getAttribute("action").replace(/\/$/, "")}/autocomplete`, location.href)
    url.searchParams.set("q", term)
    const response = await fetch(url, { headers: { Accept: "application/json" } })
    if (!response.ok) return

    const names = await response.json()
    this.list.replaceChildren(...names.map((name) => Object.assign(document.createElement("option"), { value: name })))
  }
}
