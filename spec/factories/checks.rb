FactoryGirl.define do
  factory :check do
    started_at nil
    completed_at nil
    link_warnings Array.new
    link_errors Array.new

    trait :with_error do
      problem_summary { I18n.t(:page_not_found) }
      link_errors { [I18n.t('page_was_not_found.singular')] }
    end
  end
end
