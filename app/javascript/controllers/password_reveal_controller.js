import { Controller } from "@hotwired/stimulus"

// Shows or hides the password in the wrapped field; aria-pressed tells screen readers the current state.
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.input = this.element.querySelector("input")
    if (this.input.id) this.buttonTarget.setAttribute("aria-controls", this.input.id)
    this.buttonTarget.hidden = false
  }

  toggle() {
    const reveal = this.input.type === "password"
    this.input.type = reveal ? "text" : "password"
    this.buttonTarget.setAttribute("aria-pressed", String(reveal))
  }
}
