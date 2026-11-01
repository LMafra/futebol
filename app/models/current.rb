class Current < ActiveSupport::CurrentAttributes
  attribute :session, :ip_address, :user_agent
  delegate :user, to: :session, allow_nil: true
end
