// Stimulus for ActiveAdmin pages, loaded through ActiveAdmin.importmap (config/initializers/active_admin.rb).
import { Application } from "@hotwired/stimulus"
import ScoutsController from "controllers/scouts_controller"

const application = Application.start()
application.register("scouts", ScoutsController)
