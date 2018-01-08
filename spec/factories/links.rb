FactoryBot.define do
  factory :link do
    uri "https://www.gov.uk"

    trait :with_history do
      after(:create) do |link|
        create(:link_history, link_id: link.id)
      end
    end
  end
end
