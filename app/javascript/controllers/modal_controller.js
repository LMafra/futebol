import { Controller } from "@hotwired/stimulus"

// Creation forms in a <dialog> (ModalFormHelper). Any link with data-modal-open="<dialog id>" opens it; without
// JavaScript the link just navigates. With ?modal=<id> (e.g. back after a validation error) the server renders the
// dialog open, inline; here it becomes a real modal. Esc, "Cancelar" and a click on the backdrop close it.
export default class extends Controller {
  connect() {
    this.onTrigger = (event) => {
      const trigger = event.target.closest(`[data-modal-open="${this.element.id}"]`)
      if (!trigger) return
      event.preventDefault()
      this.fill(JSON.parse(trigger.dataset.modalValues || "{}"))
      this.open()
    }
    document.addEventListener("click", this.onTrigger)
    if (this.element.open) {
      this.element.close()
      this.open()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.onTrigger)
  }

  open() {
    if (!this.element.open) this.element.showModal()
    const field = this.element.querySelector("[aria-invalid=true]") || this.element.querySelector("[autofocus]") ||
      this.element.querySelector("input:not([type=hidden]), select, textarea")
    field?.focus()
  }

  // data-modal-values on the trigger: { element id => value }; fields get the value, other elements the text.
  fill(values) {
    Object.entries(values).forEach(([id, value]) => {
      const element = this.element.querySelector(`#${CSS.escape(id)}`)
      if (!element) return
      if ("value" in element && element.tagName !== "BUTTON") element.value = value
      else element.textContent = value
    })
  }

  close() {
    this.element.close()
  }

  backdrop(event) {
    if (event.target === this.element) this.close()
  }

  // A reload after closing should not reopen the dialog.
  closed() {
    const url = new URL(window.location.href)
    if (!url.searchParams.has("modal")) return
    url.searchParams.delete("modal")
    history.replaceState(history.state, "", url)
  }
}
