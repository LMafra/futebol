import { Controller } from "@hotwired/stimulus"

// Creation forms in a <dialog> (ModalFormHelper). Any link with data-modal-open="<dialog id>" opens it; without
// JavaScript the link just navigates. With ?modal=<id> (e.g. back after a validation error) the server renders the
// dialog open, inline; here it becomes a real modal. Esc, "Cancelar" and a click on the backdrop close it.
export default class extends Controller {
  connect() {
    this.onTrigger = (event) => {
      if (!event.target.closest(`[data-modal-open="${this.element.id}"]`)) return
      event.preventDefault()
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
    const field = this.element.querySelector("[aria-invalid=true]") ||
      this.element.querySelector("input:not([type=hidden]), select, textarea")
    field?.focus()
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
