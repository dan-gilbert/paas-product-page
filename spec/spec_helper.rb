require 'webmock/rspec'
require 'support/fake_deskpro'

WebMock.allow_net_connect!
FAKE_DESKPRO_ENDPOINT = 'api.mockendpoint.com'
FAKE_DESKPRO_API_KEY = '1:XXXXYYYYZZZZ'

RSpec.configure do |config|

	config.before(:each) do
		stub_request(:any, /#{FAKE_DESKPRO_ENDPOINT}/).to_rack(FakeDeskpro)
		stub_request(:any, /#{FAKE_DESKPRO_ENDPOINT}/).to_rack(FakeDeskpro)
	end

	config.expect_with :rspec do |expectations|
		expectations.include_chain_clauses_in_custom_matcher_descriptions = true
	end

	config.mock_with :rspec do |mocks|
		# Prevents you from mocking or stubbing a method that does not exist on
		# a real object. This is generally recommended, and will default to
		# `true` in RSpec 4.
		mocks.verify_partial_doubles = true
	end

	config.shared_context_metadata_behavior = :apply_to_host_groups
end
