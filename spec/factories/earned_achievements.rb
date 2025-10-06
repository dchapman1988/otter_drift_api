FactoryBot.define do
  factory :earned_achievement do
    association :player
    association :achievement
    association :game_session
    earned_at { Time.current }
  end
end

