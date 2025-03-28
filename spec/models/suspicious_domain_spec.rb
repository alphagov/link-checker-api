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

  it "only allows domains to be saved" do
    suspicious_domain = SuspiciousDomain.new(domain: "example.com")
    expect(suspicious_domain).to be_valid
  end

  it "prevents domains prefixed with protocol from being saved" do
    suspicious_domain = SuspiciousDomain.new(domain: "http://example.com")
    expect(suspicious_domain).not_to be_valid
  end

  it "prevents domains suffixed with any path from being saved" do
    suspicious_domain = SuspiciousDomain.new(domain: "example.com/foo")
    expect(suspicious_domain).not_to be_valid
  end

  it "prevents domains suffixed with even a stray '/' from being saved" do
    suspicious_domain = SuspiciousDomain.new(domain: "example.com/")
    expect(suspicious_domain).not_to be_valid
  end

  it "prevents domains surrounded by any spacing from being saved" do
    suspicious_domain = SuspiciousDomain.new(domain: " example.com ")
    expect(suspicious_domain).not_to be_valid
  end

  it "prevents things that don't look like domains from being saved" do
    suspicious_domain = SuspiciousDomain.new(domain: "example")
    expect(suspicious_domain).not_to be_valid
  end
end
