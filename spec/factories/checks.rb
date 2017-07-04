FactoryGirl.define do
  factory :check do
    started_at nil
    completed_at nil
    link_warnings Array.new
    link_errors Array.new
  end
end
