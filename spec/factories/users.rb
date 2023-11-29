# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "#{SecureRandom.base64(15).chars.uniq.join}#!" }
  end
end
