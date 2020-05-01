FactoryBot.define do
  factory :check do
    started_at { nil }
    completed_at { nil }
    link_warnings { [] }
    link_errors { [] }

    trait :completed do
      started_at { 10.minutes.ago }
      completed_at { DateTime.now }
    end

    trait :with_errors do
      link_errors { [I18n.t(:singular, scope: :page_was_not_found)] }
    end
  end
end
