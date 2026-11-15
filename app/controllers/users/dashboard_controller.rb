module Users
  # Personal area for the standard user role: KPIs, pending actions, pools and simulator.
  class DashboardController < ApplicationController
    before_action { authorize :users_dashboard }

    def show
      @data = Users::DashboardData.new(current_user)
    end
  end
end
