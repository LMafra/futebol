FactoryBot.define do
  factory :user, class: 'Core::User' do
    sequence(:email_address) { |n| "user#{n}@futebol.test" }
    password { 'password123' }

    trait :admin do
      admin { true }
    end
  end
end
