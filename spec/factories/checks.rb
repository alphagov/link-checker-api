FactoryGirl.define do
  factory :check do
    started_at nil
    completed_at nil
    link_warnings Hash.new
    link_errors Hash.new
  end
end
