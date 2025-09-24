FactoryBot.define do
  factory :high_score do
    association :game_session
  end
end
