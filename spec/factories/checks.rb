FactoryBot.define do
  factory :check do
    started_at { nil }
    completed_at { nil }
    link_warnings { [] }
    link_danger { [] }
    link_errors { [] }

    trait :completed do
      started_at { 10.minutes.ago }
      completed_at { Time.zone.now }
    end

    trait :with_warnings do
      link_warnings { [I18n.t(:singular, scope: :page_is_slow)] }
    end

    trait :with_danger do
      link_danger { [I18n.t(:singular, scope: :suspicious_destination)] }
    end

    trait :with_errors do
      link_errors { [I18n.t(:singular, scope: :page_was_not_found)] }
    end
  end
end
