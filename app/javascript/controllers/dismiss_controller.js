import { Controller } from "@hotwired/stimulus"

// Removes its element (admin flash toasts); without JavaScript the toast simply stays on the page.
export default class extends Controller {
  close() {
    this.element.remove()
  }
}
