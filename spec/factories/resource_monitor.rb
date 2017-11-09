FactoryGirl.define do
  factory :resource_monitor do
    service "govuk"

    transient do
      number_of_links 3
    end

    after(:create) do |resource, evaluator|
      resource.links << create_list(:link, evaluator.number_of_links)
    end
  end
end
