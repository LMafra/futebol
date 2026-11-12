import { Controller } from "@hotwired/stimulus"

// Copies the source text (the Pix key) and confirms on the button for a moment.
export default class extends Controller {
  static targets = ["source", "button", "status"]

  async copy() {
    const label = this.buttonTarget.textContent
    let message
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
      message = "Copiada!"
    } catch {
      message = "Selecione e copie"
    }
    this.buttonTarget.textContent = message
    if (this.hasStatusTarget) this.statusTarget.textContent = message === "Copiada!" ? "Chave Pix copiada." : message
    setTimeout(() => {
      this.buttonTarget.textContent = label
      if (this.hasStatusTarget) this.statusTarget.textContent = ""
    }, 2000)
  }
}
