FactoryBot.define do
  factory :player do
    sequence(:email) { |n| "player#{n}@otterdrift.com" }
    sequence(:username) { |n| "otter_player_#{n}" }
    display_name { Faker::Internet.username(specifier: 3..15) }
    password { "password123" }
    password_confirmation { "password123" }
    
    trait :with_games do
      games_played { rand(1..100) }
      total_score { rand(1000..50000) }
      last_played_at { rand(1..30).days.ago }
    end
    
    trait :pro_player do
      games_played { rand(500..1000) }
      total_score { rand(100000..500000) }
    end
  end
end
