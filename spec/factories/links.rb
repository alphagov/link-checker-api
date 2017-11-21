FactoryGirl.define do
  factory :link do
    uri "https://www.gov.uk"

    trait :with_history do
      association :link_history
    end
  end
end
