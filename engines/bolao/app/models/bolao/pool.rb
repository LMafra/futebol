module Bolao
  class Pool < ApplicationRecord
    CODE_LENGTH = 6
    # No 0/O or 1/I: codes are read aloud and typed by hand.
    CODE_ALPHABET = %w[A B C D E F G H J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9].freeze
    MAX_CODE_ATTEMPTS = 10

    belongs_to :championship, class_name: 'Core::Championship'
    belongs_to :owner, class_name: 'Core::User'
    has_many :predictions, class_name: 'Bolao::Prediction', dependent: :restrict_with_error
    has_one :scoring_rule, class_name: 'Bolao::ScoringRule', dependent: :destroy
    has_many :memberships, class_name: 'Bolao::PoolMembership', dependent: :destroy
    has_many :members, through: :memberships, source: :user

    accepts_nested_attributes_for :scoring_rule, allow_destroy: true, reject_if: :all_blank

    before_validation :assign_code, on: :create
    after_create :add_owner_as_member

    validates :name, presence: true
    validates :code, presence: true, length: { is: CODE_LENGTH }, uniqueness: true

    def self.ransackable_attributes(_auth_object = nil) = %w[name championship_id code]
    def self.ransackable_associations(_auth_object = nil) = %w[championship]

    def self.generate_code = Array.new(CODE_LENGTH) { CODE_ALPHABET.sample(random: SecureRandom) }.join

    def self.normalize_code(code) = code.to_s.strip.upcase

    def member?(user) = user.present? && memberships.exists?(user_id: user.id)

    def owned_by?(user) = user.present? && owner_id == user.id

    def to_s = name

    private

    # One query for all candidates; if every one is taken, code stays blank and validation fails.
    def assign_code
      return if code.present?

      candidates = Array.new(MAX_CODE_ATTEMPTS) { self.class.generate_code }.uniq
      self.code = (candidates - self.class.where(code: candidates).pluck(:code)).first
    end

    def add_owner_as_member
      memberships.create!(user: owner)
    end
  end
end
