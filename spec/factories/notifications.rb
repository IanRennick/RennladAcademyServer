FactoryBot.define do
  factory :notification do
    recipient { nil }
    actor { nil }
    event_type { "MyString" }
    read_at { "2026-07-18 14:56:41" }
    params { "" }
  end
end
