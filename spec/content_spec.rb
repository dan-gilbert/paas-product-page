ENV['RACK_ENV'] = 'test'
ENV['DESKPRO_API_KEY'] = FAKE_DESKPRO_API_KEY
ENV['DESKPRO_ENDPOINT'] = FAKE_DESKPRO_ENDPOINT
ENV['DESKPRO_TEAM_ID'] = '1'

require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe "Content", :type => :feature do

	include Rack::Test::Methods

	seen = {}
	Dir['views/*.erb'].each do |template|
		next if /layout.erb/.match?(template)
		parent_path = template.gsub(/.erb$/, '').gsub(/^views/, '').gsub(/#.*/, '')
		it "should not have broken links in #{template}" do
			visit parent_path
			expect(page.status_code).to eq(200), "Failed to load page '#{parent_path}'"
			all('a').each do |link|
				url = link[:href]
				next if url.nil? or url.empty? or url.match?(/^#/) or seen[url]
				if url =~ /^https?:/
					res = Net::HTTP.get_response(URI(url))
					expect(res.code).to match(/^(200|301|302)$/), "there is a broken (#{res.code}) EXTERNAL link to '#{url}' on '#{parent_path}'"
				elsif url =~ /^\//
					visit url
					expect(page.status_code).to eq(200), "there is a broken (#{page.status_code}) link to '#{url}' on '#{parent_path}'"
				elsif url =~ /^mailto:/
					expect(url).to match(/^.+@.+$/)
				else
					fail "there is an invalid url '#{url}' on '#{parent_path}'"
				end
				seen[url] = true
			end
		end
	end

end
