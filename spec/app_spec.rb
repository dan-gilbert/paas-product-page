ENV['RACK_ENV'] = 'test'
ENV['DESKPRO_API_KEY'] = FAKE_DESKPRO_API_KEY
ENV['DESKPRO_ENDPOINT'] = FAKE_DESKPRO_ENDPOINT
ENV['DESKPRO_TEAM_ID'] = '1'

require 'rack/test'

RSpec.describe "App" do

	include Rack::Test::Methods

	def app()
		Rack::Builder.parse_file("config.ru").first
	end

	it "renders an index page" do
		get '/'
		expect(last_response).to be_ok
	end

	it "renders a registration form" do
		get '/register'
		expect(last_response).to be_ok
	end

	it "renders a support form" do
		get '/support'
		expect(last_response).to be_ok
	end

	it "can submit the registration form" do
		post '/register', {
			"person_name" => "jeff",
			"person_email" => "jeff@local.local",
		}
		expect(last_response).to be_ok
	end

	it "can submit the support form" do
		post '/support', {
			"person_name" => "jeff",
			"person_email" => "jeff@local.local",
			"message" => "new signup",
		}
		expect(last_response).to be_ok
	end

	# it "should not have a X-Frame-Options header in response" do
	# 	get '/support'
	# 	expect(last_response.header['X-Frame-Options']).to eq(nil)
	# end

	# it "should disallow robots via X-Robots-Tag" do
	# 	get '/'
	# 	expect(last_response.header['X-Robots-Tag']).to eq('noindex, nofollow')
	# end

end
