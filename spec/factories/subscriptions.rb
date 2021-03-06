FactoryBot.define do
  factory :subscription do
    expires_on { Time.zone.today.strftime('%Y-%m-%d') }
    email { Faker::Internet.email }
    reference { Faker::Lorem.sentence }
    frequency { :daily }

    factory :daily_subscription do
      frequency { :daily }
      expires_on { 3.months.from_now }
    end
  end
end
