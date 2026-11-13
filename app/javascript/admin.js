// Stimulus for ActiveAdmin pages, loaded through ActiveAdmin.importmap (config/initializers/active_admin.rb).
import { Application } from "@hotwired/stimulus"
import AutocompleteController from "controllers/autocomplete_controller"
import CollectionController from "controllers/collection_controller"
import DismissController from "controllers/dismiss_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import ScoutsController from "controllers/scouts_controller"

// The admin is light-only (docs/design/0001-critique.md Q5). AA's dark_mode_toggle adds `.dark` on
// DOMContentLoaded from the OS preference unless a theme is stored; module scripts run before that event.
localStorage.setItem("theme", "light")
document.documentElement.classList.remove("dark")

// AA's main_menu.js toggles `data-open` on the section <li>; mirror it on the toggle buttons for screen readers.
document.addEventListener("click", (event) => {
  const button = event.target.closest("#main-menu button[data-menu-button]")
  if (!button) return

  setTimeout(() => {
    const section = button.closest("[data-item-id]")
    button.setAttribute("aria-expanded", "open" in section.dataset)
  })
})

// The filter bar renders open (no-JS safe); on phones it starts collapsed unless a filter is active.
const desktop = window.matchMedia("(min-width: 768px)")
const syncFilters = () => {
  const filtered = [...new URLSearchParams(location.search).keys()].some((key) => key.startsWith("q["))
  document.querySelectorAll("details[data-filters-collapsible]").forEach((details) => {
    details.open = desktop.matches || filtered
  })
}
document.addEventListener("DOMContentLoaded", syncFilters)
desktop.addEventListener("change", syncFilters)

const application = Application.start()
application.register("autocomplete", AutocompleteController)
application.register("collection", CollectionController)
application.register("dismiss", DismissController)
application.register("image-preview", ImagePreviewController)
application.register("scouts", ScoutsController)
