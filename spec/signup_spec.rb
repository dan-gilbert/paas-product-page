ENV['RACK_ENV'] = 'test'
ENV['DESKPRO_API_KEY'] = FAKE_DESKPRO_API_KEY
ENV['DESKPRO_ENDPOINT'] = FAKE_DESKPRO_ENDPOINT
ENV['DESKPRO_TEAM_ID'] = '1'

require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe "Signup", :type => :feature do

	include Rack::Test::Methods

	it "should submit the form successfully" do
		visit '/signup'
		fill_in('person_name', with: 'Jeff Jefferson')
		fill_in('person_email', with: 'jeff@test.gov.uk')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		click_button('signup-submit')
		all('.error-message').each do |err|
			expect(err.text).to be_empty, "Did not expect to see any validation errors but got: #{err.text}"
		end
		all('.error-summary .err').each do |err|
			expect(err.text).to be_empty, "Did not expect to see a summary of errors but got: #{err.text}"
		end
		expect(page.status_code).to eq(200)
	end

	it "should require person_name field" do
		visit '/signup'
		fill_in('person_email', with: 'jeff@test.gov.uk')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		click_button('signup-submit')
		expect(page.first('.form-group--person_name .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require person_email field" do
		visit '/signup'
		fill_in('person_name', with: 'jeff')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		click_button('signup-submit')
		expect(page.first('.form-group--person_email .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require a valid email for person_email" do
		visit '/signup'
		fill_in('person_name', with: 'jeff')
		fill_in('person_email', with: 'not-an-email')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		click_button('signup-submit')
		expect(page.first('.form-group--person_email .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require a .gov.uk email for person_email" do
		visit '/signup'
		fill_in('person_name', with: 'jeff')
		fill_in('person_email', with: 'jeff@gmail.com')
		fill_in('department_name', with: 'TestDept')
		fill_in('service_name', with: 'TestService')
		click_button('signup-submit')
		expect(page.first('.form-group--person_email .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require department_name field" do
		visit '/signup'
		fill_in('person_name', with: 'jeff')
		fill_in('person_email', with: 'jeff@test.gov.uk')
		fill_in('service_name', with: 'TestService')
		click_button('signup-submit')
		expect(page.first('.form-group--department_name .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

	it "should require service_name field" do
		visit '/signup'
		fill_in('person_name', with: 'jeff')
		fill_in('person_email', with: 'jeff@test.gov.uk')
		fill_in('department_name', with: 'TestDept')
		click_button('signup-submit')
		expect(page.first('.form-group--service_name .error-message').text).not_to be_empty
		expect(page.status_code).to eq(400)
	end

end
