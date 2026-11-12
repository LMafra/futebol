import { Controller } from "@hotwired/stimulus"

// Staged disclosure for the championship create form: shows one fieldset at a time, still a single POST.
// Inert unless the server rendered the step nav (new records only); without JavaScript every fieldset stays visible.
export default class extends Controller {
  static targets = ["nav", "step", "stepLink", "progress", "back", "next"]

  connect() {
    if (!this.hasNavTarget || this.stepTargets.length < 2) return

    this.navTarget.hidden = false
    const failing = this.stepTargets.findIndex((step) => step.querySelector(".error, .inline-errors"))
    this.show(failing >= 0 ? failing : 0)
  }

  next(event) {
    event.preventDefault()
    if (!this.validStep()) return
    this.show(this.index + 1, { focus: true })
  }

  back(event) {
    event.preventDefault()
    this.show(this.index - 1, { focus: true })
  }

  jump(event) {
    event.preventDefault()
    const target = Number(event.currentTarget.dataset.step)
    if (target > this.index && !this.validStep()) return
    this.show(target, { focus: true })
  }

  // Enter in a field submits the form; before the last step it advances instead.
  submitOrAdvance(event) {
    if (event.key !== "Enter" || event.target.tagName !== "INPUT") return
    if (!this.hasNavTarget || this.navTarget.hidden || this.index === this.stepTargets.length - 1) return

    event.preventDefault()
    this.next(event)
  }

  show(index, { focus = false } = {}) {
    const last = this.stepTargets.length - 1
    this.index = Math.min(Math.max(index, 0), last)

    this.stepTargets.forEach((step, position) => { step.hidden = position !== this.index })
    this.stepLinkTargets.forEach((link, position) => {
      if (position === this.index) link.setAttribute("aria-current", "step")
      else link.removeAttribute("aria-current")
    })
    this.progressTarget.textContent = `Etapa ${this.index + 1} de ${this.stepTargets.length}`
    this.backTarget.hidden = this.index === 0
    this.nextTarget.hidden = this.index === last
    const actions = this.element.querySelector("fieldset.actions")
    if (actions) actions.hidden = this.index !== last

    if (focus) this.stepTargets[this.index].querySelector("input, select, textarea, legend")?.focus()
  }

  validStep() {
    const fields = [...this.stepTargets[this.index].querySelectorAll("input, select, textarea")]
    return fields.every((field) => field.reportValidity())
  }
}
