import { Controller } from "@hotwired/stimulus"

// Admin "Scouts da partida": switches between the Mandante and Visitante tables (WAI-ARIA tabs: arrows, Home, End),
// steps the counters within their
// min/max, marks "Jogou" for the visible side and previews SG and each player's points. The server recomputes
// both on save; without JavaScript the number inputs still work.
export default class extends Controller {
  static targets = ["tab", "team", "row"]
  static values = { weights: Object }

  connect() {
    this.refresh()
  }

  show({ params: { side } }) {
    this.select(side)
  }

  navigate(event) {
    const tabs = this.tabTargets
    const current = tabs.indexOf(event.target)
    if (current < 0) return

    const next = { ArrowRight: current + 1, ArrowLeft: current - 1, Home: 0, End: tabs.length - 1 }[event.key]
    if (next === undefined) return

    event.preventDefault()
    const tab = tabs[(next + tabs.length) % tabs.length]
    this.select(tab.dataset.side)
    tab.focus()
  }

  select(side) {
    this.teamTargets.forEach((team) => { team.hidden = team.dataset.side !== side })
    this.tabTargets.forEach((tab) => {
      const selected = tab.dataset.side === side
      tab.setAttribute("aria-selected", selected)
      tab.tabIndex = selected ? 0 : -1
    })
  }

  step({ currentTarget, params: { delta } }) {
    const input = currentTarget.parentElement.querySelector("input[type=number]")
    if (!input || input.disabled) return

    const next = Number(input.value || 0) + delta
    input.value = Math.min(Math.max(next, Number(input.min)), Number(input.max))
    this.refresh()
  }

  toggleAll({ currentTarget }) {
    const team = currentTarget.closest("[data-scouts-target='team']")
    team.querySelectorAll("input[data-scout='played']").forEach((box) => { box.checked = currentTarget.checked })
    this.refresh()
  }

  refresh() {
    const rows = this.rowTargets.map((row) => ({ row, side: row.dataset.side, stats: this.stats(row) }))
    const total = (side, stat) => rows.filter((entry) => entry.side === side)
      .reduce((sum, entry) => sum + entry.stats[stat], 0)
    const conceded = {
      home: total("away", "goals") + total("home", "own_goals"),
      away: total("home", "goals") + total("away", "own_goals")
    }

    rows.forEach(({ row, side, stats }) => {
      stats.clean_sheet = stats.played && conceded[side] === 0
      row.querySelector("[data-role='clean-sheet']").textContent = stats.clean_sheet ? "SG" : "–"
      if (Object.keys(this.weightsValue).length > 0) {
        row.querySelector("[data-role='points']").textContent = this.points(stats).toFixed(2)
      }
    })
  }

  stats(row) {
    const stats = {}
    row.querySelectorAll("input[data-scout]").forEach((input) => {
      stats[input.dataset.scout] = input.type === "number" ? Number(input.value || 0) : input.checked
    })
    return stats
  }

  points(stats) {
    return Object.entries(this.weightsValue)
      .reduce((sum, [stat, weight]) => sum + Number(stats[stat] || 0) * weight, 0)
  }
}
