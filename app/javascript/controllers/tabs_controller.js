import { Controller } from "@hotwired/stimulus"

// ARIA tabs (tablist/tab/tabpanel) with arrow keys, Home and End. Without JavaScript every panel stays visible. The
// selected tab survives the reload after a form on the same page (sessionStorage, per path).
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const stored = sessionStorage.getItem(this.storageKey)
    const tab = this.tabTargets.find((candidate) => candidate.id === stored) || this.tabTargets[0]
    if (tab) this.show(tab)
  }

  select(event) {
    this.show(event.currentTarget)
    sessionStorage.setItem(this.storageKey, event.currentTarget.id)
  }

  navigate(event) {
    const index = this.tabTargets.indexOf(document.activeElement)
    if (index === -1) return

    const last = this.tabTargets.length - 1
    const next = { ArrowRight: index + 1, ArrowLeft: index - 1, Home: 0, End: last }[event.key]
    if (next === undefined) return

    event.preventDefault()
    const tab = this.tabTargets[(next + last + 1) % (last + 1)]
    this.show(tab)
    sessionStorage.setItem(this.storageKey, tab.id)
    tab.focus()
  }

  show(selected) {
    this.tabTargets.forEach((tab) => {
      const active = tab === selected
      tab.setAttribute("aria-selected", active)
      tab.tabIndex = active ? 0 : -1
    })
    this.panelTargets.forEach((panel) => {
      panel.hidden = panel.getAttribute("aria-labelledby") !== selected.id
    })
  }

  get storageKey() {
    return `tabs:${window.location.pathname}`
  }
}
