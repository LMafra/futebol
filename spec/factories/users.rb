FactoryBot.define do
  factory :user, class: 'Core::User' do
    sequence(:email_address) { |n| "user#{n}@futebol.test" }
    password { 'password123' }
    name { 'Torcedor Teste' }
    sequence(:cpf) { |n| format('%011d', n) }

    trait :admin do
      admin { true }
      role { :admin }
    end

    trait :manager do
      role { :manager }
      manager_status { :approved }
    end

    trait :pending_manager do
      manager_status { :pending }
    end
  end
end
