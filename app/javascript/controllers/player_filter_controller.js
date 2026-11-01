import { Controller } from "@hotwired/stimulus"

// Shows only the player group of the chosen position (Cartola::PlayerPickerComponent).
export default class extends Controller {
  static targets = ["group"]

  filter(event) {
    const position = event.target.value
    this.groupTargets.forEach((group) => {
      group.hidden = position !== "" && group.dataset.position !== position
    })
  }
}
