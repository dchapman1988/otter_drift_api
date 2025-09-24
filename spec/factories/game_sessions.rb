FactoryBot.define do
  factory :game_session do
    player_name { Faker::Name.first_name }
    seed { rand(1..10_000) }
    started_at { Time.current }
    ended_at   { started_at + rand(60..600).seconds }
    final_score { rand(0..10_000) }
    game_duration { (ended_at - started_at).to_f }
    max_speed_reached { rand.round(2) }
    obstacles_avoided { rand(0..100) }
    lilies_collected  { rand(0..50) }
    session_id { SecureRandom.uuid }
  end
end
