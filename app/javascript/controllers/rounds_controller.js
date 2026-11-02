import { Controller } from "@hotwired/stimulus"

// Shows one round of open matches at a time, with previous/next buttons. Hidden rounds stay in the form, so
// every guess is still submitted; without JS all rounds stay stacked and the nav stays hidden.
export default class extends Controller {
  static targets = ["round", "nav", "label", "previous", "next", "position"]
  static values = { index: Number }

  connect() {
    if (this.roundTargets.length < 2) return

    this.navTarget.hidden = false
    this.show(this.indexValue)
  }

  previous() {
    this.show(this.indexValue - 1)
  }

  next() {
    this.show(this.indexValue + 1)
  }

  show(index) {
    const last = this.roundTargets.length - 1
    this.indexValue = Math.min(Math.max(index, 0), last)
    this.roundTargets.forEach((round, position) => { round.hidden = position !== this.indexValue })
    this.labelTarget.textContent =
      `${this.roundTargets[this.indexValue].dataset.roundLabel} · ${this.indexValue + 1} de ${last + 1}`
    this.previousTarget.disabled = this.indexValue === 0
    this.nextTarget.disabled = this.indexValue === last
    this.positionTarget.value = this.indexValue
  }
}
