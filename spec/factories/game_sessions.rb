FactoryBot.define do
  factory :game_session do
    sequence(:session_id) { |n| "session_#{n}_#{SecureRandom.hex(8)}" }
    player_name { Faker::Internet.username }
    seed { rand(1..999999) }
    started_at { 2.minutes.ago }
    ended_at { nil }
    final_score { nil }
    game_duration { nil }
    max_speed_reached { nil }
    obstacles_avoided { nil }
    lilies_collected { nil }

    trait :completed do
      ended_at { Time.current }
      final_score { rand(100..10000) }
      game_duration { rand(30..300) }
      max_speed_reached { rand(10.0..30.0).round(2) }
      obstacles_avoided { rand(0..50) }
      lilies_collected { rand(0..100) }
    end

    trait :with_player do
      association :player
    end

    trait :guest do
      player { nil }
    end

    trait :high_score do
      completed
      final_score { rand(5000..10000) }
      lilies_collected { rand(50..100) }
    end
  end
end
