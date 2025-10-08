FactoryBot.define do
  factory :player_profile do
    bio { Faker::Lorem.paragraph  }
    favorite_otter_fact { Faker::Lorem.sentence }
    title { Faker::Lorem.word }
    profile_banner_url { Faker::Internet.url }
    location { "USA" }
    association :player
  end
end
