FactoryBot.define do
  factory :link_history do
    link_errors Array.new

    trait :with_link do
      association :link
    end

    trait :with_history do
      link_errors { [{ message: I18n.t(:singular, scope: :page_was_not_found), started_at: 1.day.ago }] }
    end
  end
end
