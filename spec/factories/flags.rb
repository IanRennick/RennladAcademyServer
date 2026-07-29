FactoryBot.define do
  factory :flag do
    report_type { 1 }
    body { "MyText" }
    status { 1 }
    user { nil }
    commentable { nil }
  end
end
