import { Controller } from "@hotwired/stimulus"

// Previews the chosen crest/logo under the file input and flags files over the size limit before upload.
export default class extends Controller {
  static values = { maxBytes: Number }

  disconnect() {
    this.#revoke()
  }

  show() {
    const file = this.element.files[0]
    this.#revoke()
    this.preview?.remove()
    this.element.setCustomValidity("")
    if (!file) return

    if (this.hasMaxBytesValue && file.size > this.maxBytesValue) {
      this.element.setCustomValidity("A imagem deve ter até 2 MB.")
      this.element.reportValidity()
      return
    }

    this.url = URL.createObjectURL(file)
    this.preview = document.createElement("img")
    this.preview.src = this.url
    this.preview.alt = "Prévia da imagem escolhida"
    this.preview.className = "mt-2 size-24 rounded-md border border-rule bg-white object-contain"
    this.preview.dataset.role = "image-preview"
    this.element.insertAdjacentElement("afterend", this.preview)
  }

  #revoke() {
    if (this.url) URL.revokeObjectURL(this.url)
    this.url = null
  }
}
