require "rails_helper"
require "pact/v2"
require "pact/v2/rspec"

RSpec.describe "Verify consumers for Link Checker API", :pact_v2 do
  Pact::V2.configure do |config|
    config.before_provider_state_setup do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
      GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin])
    end

    config.after_provider_state_teardown do
      DatabaseCleaner.clean
    end
  end

  http_pact_provider "Link Checker API", opts: {
    http_port: 9292,
    pact_uri: ENV["PACT_URI"],
    broker_url: ENV.fetch("PACT_BROKER_BASE_URL", "https://govuk-pact-broker-6991351eca05.herokuapp.com"),
    consumer_name: "GDS API Adapters",
    consumer_version_selectors: [
      { branch: ENV.fetch("PACT_CONSUMER_VERSION", "branch-main").delete_prefix("branch-") },
    ],
    log_level: :info,
    fail_if_no_pacts_found: true,
  }

  provider_state "a batch exists with id 99 and uris https://www.gov.uk" do
    set_up do
      link = FactoryBot.create(:link, uri: "https://www.gov.uk")
      check = FactoryBot.create(:check, link:)
      FactoryBot.create(:batch, id: 99, checks: [check])
    end
  end
end
