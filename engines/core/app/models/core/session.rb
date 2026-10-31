module Core
  class Session < ApplicationRecord
    belongs_to :user, class_name: 'Core::User'
  end
end
