import { Controller } from "@hotwired/stimulus"

// Copies the source text (the Pix key) and confirms on the button for a moment.
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const label = this.buttonTarget.textContent
    try {
      await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
      this.buttonTarget.textContent = "Copiada!"
    } catch {
      this.buttonTarget.textContent = "Selecione e copie"
    }
    setTimeout(() => { this.buttonTarget.textContent = label }, 2000)
  }
}
