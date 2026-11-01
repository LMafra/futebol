# Base controller for Mission Control Jobs (config.mission_control.jobs.base_controller_class).
class JobsDashboardController < ApplicationController
  skip_after_action :verify_policy_scoped

  before_action { authorize :jobs_dashboard, :show? }

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
end
