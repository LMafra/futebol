import { Controller } from "@hotwired/stimulus"

// Same format as Bolao::MatchListComponent#countdown_label: "2d 04:05:06".
export default class extends Controller {
  static values = { deadline: String, closed: { type: String, default: "Palpites encerrados" } }

  connect() {
    this.tick()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  tick() {
    const seconds = Math.floor((Date.parse(this.deadlineValue) - Date.now()) / 1000)
    if (seconds <= 0) {
      this.element.textContent = this.closedValue
      clearInterval(this.timer)
      return
    }

    const days = Math.floor(seconds / 86400)
    const clock = [Math.floor(seconds / 3600) % 24, Math.floor(seconds / 60) % 60, seconds % 60]
      .map((part) => String(part).padStart(2, "0"))
      .join(":")
    this.element.textContent = `${days}d ${clock}`
  }
}
