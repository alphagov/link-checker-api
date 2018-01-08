FactoryBot.define do
  factory :resource_monitor do
    app "govuk"
    reference "Test:1"

    transient do
      number_of_links 3
    end

    after(:create) do |resource, evaluator|
      resource.links << create_list(:link, evaluator.number_of_links, :with_history)
    end
  end
end
