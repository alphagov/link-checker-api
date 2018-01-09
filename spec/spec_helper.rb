require "pry"
require "byebug"
require "webmock/rspec"
require "timecop"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.expose_dsl_globally = false

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.after do
    Timecop.return
  end
end
