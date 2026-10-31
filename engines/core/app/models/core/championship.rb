module Core
  class Championship < ApplicationRecord
    has_many :matches, class_name: 'Core::Match', dependent: :restrict_with_error

    validates :name, presence: true
    validates :season, numericality: { only_integer: true, in: 1900..2100 }
    validates :external_id, presence: true, uniqueness: true

    def to_s = "#{name} #{season}"
  end
end
