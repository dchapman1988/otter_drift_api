FactoryBot.define do
  factory :high_score do
    association :game_session, factory: [:game_session, :completed]
    score { game_session&.final_score || rand(100..10000) }
  end
end
