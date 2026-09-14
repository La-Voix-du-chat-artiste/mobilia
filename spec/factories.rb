FactoryBot.define do
  factory :company do
    sequence(:name) { |number| "Transports #{number}" }
  end

  factory :user do
    company
    sequence(:email) { |number| "user#{number}@example.test" }
    first_name { 'Camille' }
    last_name { 'Martin' }
    password { 'password123' }
    password_confirmation { 'password123' }

    factory :admin do
      role { :admin }
    end

    factory :super_admin do
      role { :super_admin }
    end
  end

  factory :transporter do
    company
    sequence(:email) { |number| "driver#{number}@example.test" }
    first_name { 'Jean' }
    last_name { 'Dupont' }
    password { 'password123' }
    password_confirmation { 'password123' }
    address_attributes { { label: '1 place Bellecour, 69002 Lyon' } }
    # Mirrors what the transporter form submits; the optimiser needs it.
    availabilities do
      { monday: 'all_day', tuesday: 'all_day', wednesday: 'all_day',
        thursday: 'all_day', friday: 'all_day',
        saturday: 'no_work', sunday: 'no_work' }
    end

    # A driver whose availability nobody has stated: json column default {}.
    trait :without_availabilities do
      availabilities { {} }
    end
  end

  factory :customer do
    company
    first_name { 'Élodie' }
    last_name { 'Nguyen' }
    address_attributes { { label: '10 rue de la Paix, 75002 Paris' } }
  end

  factory :place do
    company
    name { 'Clinique Saint-Jean' }
    address_attributes { { label: '1 place Bellecour, 69002 Lyon' } }
  end

  factory :vehicle do
    company
    name { 'Kangoo' }
    sequence(:number_plate) { |number| format('AB-%03d-CD', number) }
    max_regular_seats { 3 }
    max_wheelchair_seats { 1 }
  end

  factory :daily_quest do
    company
    started_on { Date.current }
  end

  factory :absence do
    transporter
    started_on { Date.current }
    ended_on { Date.current }
  end

  factory :mission do
    daily_quest
    customer
    place
    drop_time { '09:30' }
    round_trip { false }
  end
end
