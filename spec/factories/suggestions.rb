FactoryBot.define do
  factory :suggestion do
    note { Faker::Lorem.paragraph }

    trait :from_guest do
      player { nil }
    end

    trait :from_player do
      player { create(:player) }
    end
  end
end
