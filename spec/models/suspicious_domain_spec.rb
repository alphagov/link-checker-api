require "rails_helper"

RSpec.describe SuspiciousDomain, type: :model do
  it "has a 'domain' property" do
    suspicious_domain = SuspiciousDomain.new(domain: "malicious.example.com")
    expect(suspicious_domain.domain).to eq("malicious.example.com")
  end

  it "doesn't allow the same domain twice" do
    SuspiciousDomain.destroy_all
    domain = "malicious.example.com"

    # Locally, the database constraint triggers first, raising RecordNotUnique.
    # On CI, Rails' uniqueness validation runs first, raising RecordInvalid instead.
    # Hence the need for this slightly smelly test.
    begin
      SuspiciousDomain.create!(domain:)
      SuspiciousDomain.create!(domain:)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      expect([ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique]).to include(e.class)
    end
  end
end
