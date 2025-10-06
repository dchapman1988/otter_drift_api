FactoryBot.define do
  factory :achievement do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    icon_url { Faker::Internet.url }
    points { rand(10..100) }
    hidden { false }
    
    factory :lily_collector, class: 'Achievement::LilyCollector' do
      type { "Achievement::LilyCollector" }
      name { "Lily Collector!" }
      description { "Collect 10 lilies in a single game." }
      icon_url { "https://example.com/lily.png" }
      points { 10 }
      hidden { false }
    end
    
    factory :heart_hoarder, class: 'Achievement::HeartHoarder' do
      type { "Achievement::HeartHoarder" }
      name { "Heart Hoarder" }
      description { "Collect 20 hearts in a single game." }
      icon_url { "https://example.com/heart.png" }
      points { 15 }
      hidden { false }
    end
  end
end
