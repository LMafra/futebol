// Stimulus for ActiveAdmin pages, loaded through ActiveAdmin.importmap (config/initializers/active_admin.rb).
import { Application } from "@hotwired/stimulus"
import ScoutsController from "controllers/scouts_controller"

// The admin is light-only (docs/design/0001-critique.md Q5). AA's dark_mode_toggle adds `.dark` on
// DOMContentLoaded from the OS preference unless a theme is stored; module scripts run before that event.
localStorage.setItem("theme", "light")
document.documentElement.classList.remove("dark")

const application = Application.start()
application.register("scouts", ScoutsController)
