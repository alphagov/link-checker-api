require "pact/provider/rspec"
require "webmock/rspec"
require "factory_bot_rails"

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include FactoryBot::Syntax::Methods
end

WebMock.allow_net_connect!

def url_encode(str)
  ERB::Util.url_encode(str)
end

Pact.service_provider "Link Checker API" do
  honours_pact_with "GDS API Adapters" do
    if ENV["PACT_URI"]
      pact_uri(ENV["PACT_URI"])
    else
      base_url = "https://govuk-pact-broker-6991351eca05.herokuapp.com"
      path = "pacts/provider/#{url_encode(name)}/consumer/#{url_encode(consumer_name)}"
      version_modifier = "versions/#{url_encode(ENV.fetch('PACT_CONSUMER_VERSION', 'branch-master'))}"

      pact_uri("#{base_url}/#{path}/#{version_modifier}")
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    GDS::SSO.test_user = create(:user, permissions: %w[signin])
  end

  tear_down do
    DatabaseCleaner.clean
  end

  provider_state "a batch exists with id 99 and uris https://www.gov.uk" do
    set_up do
      link = create(:link, uri: "https://www.gov.uk")
      check = create(:check, link:)
      create(:batch, id: 99, checks: [check])
    end
  end
end
