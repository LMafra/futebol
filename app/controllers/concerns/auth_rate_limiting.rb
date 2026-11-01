module AuthRateLimiting
  extend ActiveSupport::Concern

  MAX_ATTEMPTS = 5
  WINDOW = 3.minutes

  class_methods do
    # Counts live in the controller cache store (Solid Cache in production), keyed by client IP.
    def limit_auth_attempts(only: :create)
      rate_limit to: MAX_ATTEMPTS, within: WINDOW, only:, with: -> { reject_rate_limited_attempt }
    end
  end

  private

  def reject_rate_limited_attempt
    Rails.logger.warn("rate_limited #{controller_name}##{action_name} ip=#{request.remote_ip}")
    flash.now[:alert] = 'Muitas tentativas. Aguarde alguns minutos e tente novamente.'
    render :new, status: :too_many_requests
  end
end
