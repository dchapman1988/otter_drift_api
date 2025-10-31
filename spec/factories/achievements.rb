FactoryBot.define do
  factory :achievement do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    icon_url { Faker::Internet.url }
    points { rand(10..100) }
    hidden { false }
    achievement_type { Faker::Lorem.unique.word }

    factory :lily_collector_achievement do
      achievement_type { "lily_collector" }
      name { "Lily Collector" }
      description { "Collect 10 lilies in a single game" }
      icon_url { "https://example.com/lily.png" }
      points { 100 }
      hidden { false }
    end

    factory :heart_hoarder_achievement do
      achievement_type { "heart_hoarder" }
      name { "Heart Hoarder" }
      description { "Collect 20 hearts in a single game" }
      icon_url { "https://example.com/heart.png" }
      points { 150 }
      hidden { false }
    end
  end
end
