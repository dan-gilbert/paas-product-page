require 'sinatra/base'
require 'json'

# FakeDeskpro is a mocked version of the Deskpro API endpoint
class FakeDeskpro < Sinatra::Base
	post '/api/tickets' do
		content_type :json
		status 201
		{:ticket_id => 100001}.to_json
	end
end
