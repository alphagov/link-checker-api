FactoryGirl.define do
  factory :monitor_link do
    last_checked_at { DateTime.now }
    link_errors Array.new

    trait :with_history do
      link_errors { [{ message: I18n.t(:singular, scope: :page_was_not_found), started_at: 1.day.ago }] }
    end
  end
end
