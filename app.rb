require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'sinatra/multi_route'
require 'staccato'
require 'sprockets'
require 'sprockets-helpers'
require 'json'

require './models/deskpro'

# App is the main Sinatra application
class App < Sinatra::Base

	set :sprockets, Sprockets::Environment.new
	set :title, 'Gov.UK Platform as a Service'
	enable :sessions

	configure do
		sprockets.append_path File.join(root, 'node_modules', 'govuk_frontend_toolkit', 'stylesheets')
		sprockets.append_path File.join(root, 'node_modules', 'govuk-elements-sass', 'public', 'sass')
		sprockets.append_path File.join(root, 'node_modules', 'govuk_template_mustache', 'assets', 'stylesheets')
		sprockets.append_path File.join(root, 'assets', 'stylesheets')
		sprockets.append_path File.join(root, 'assets', 'fonts')
		sprockets.append_path File.join(root, 'assets', 'js')
		Sprockets::Helpers.configure do |config|
			config.environment = sprockets
			config.public_path = public_folder
			config.debug       = true if development?
		end
		register Sinatra::Reloader if development?
		register Sinatra::MultiRoute
	end

	helpers Sinatra::ContentFor
	helpers Sprockets::Helpers

	get '/?' do
		erb :index
	end

	get "/assets/*" do
		env["PATH_INFO"].sub!("/assets", "")
		settings.sprockets.call(env)
	end

	get '/contact-us' do
		@errors = {}
		@ticket = Deskpro::Ticket.new
		erb :'contact-us'
	end

	post '/contact-us' do
		@errors = {}
		message = "department: #{params[:department_name]}\n"
		message << "service: #{params[:service_name]}\n"
		message << params[:message]
		@ticket = Deskpro::Ticket.new({
			subject: "#{Date.today.to_s} Support Request From Website",
			person_email: params[:person_email],
			person_name: params[:person_name],
			message: message,
			label: ['paas'],
		})
		@ticket.agent_team_id = ENV['DESKPRO_TEAM_ID'].to_i if ENV['DESKPRO_TEAM_ID']
		if not @ticket.valid?
			status 400
			erb :'contact-us'
		else
			begin
				deskpro.post @ticket
				track_event 'enquire'
				erb :thanks
			rescue => ex
				status 500
				@errors[:fatal] = ex.to_s
				erb :'contact-us'
			end
		end
	end

	post '/signup' do
		@form = {
			:person_email => params[:person_email] || '',
			:person_name => params[:person_name] || '',
			:person_is_manager => params[:person_is_manager] == 'true',
			:department_name => params[:department_name] || '',
			:service_name => params[:service_name],
			:invite_users => params[:invite_users] == 'true',
			:invites => [{},{},{}].map.with_index do |invite, idx|
				invite = (params[:invites] || {})[idx.to_s] || {}
				{
					:person_name => invite[:person_name] || '',
					:person_email => invite[:person_email] || '',
					:person_is_manager => invite[:person_is_manager] == 'true',
				}
			end
		}
		@errors = {}
		@form.each do |k, v|
			err = validate(k, v)
			@errors[k] = err if err.is_a? String
		end
		if @errors.size > 0
			status 400
			return erb :signup
		end
		@ticket = Deskpro::Ticket.new({
			subject: "#{Date.today.to_s} Registration Request",
			message: %{
New registration request from website:

#{JSON.pretty_generate(@form)}
			},
			person_email: @form[:person_email],
			person_name: @form[:person_name],
			label: ['paas'],
		})
		@ticket.agent_team_id = ENV['DESKPRO_TEAM_ID'].to_i if ENV['DESKPRO_TEAM_ID']
		if not @ticket.valid?
			status 400
			erb :signup
		else
			begin
				deskpro.post @ticket
				track_event 'register'
				erb :thanks
			rescue => ex
				status 500
				@errors[:fatal] = ex.to_s
				erb :signup
			end
		end
	end

	get '/signup' do
		@form = {
			:person_email => '',
			:person_name => '',
			:person_is_manager => true,
			:department_name => '',
			:service_name => '',
			:invite_users => false,
			:invites => [
				{:person_name => '', :person_email => '', :person_is_manager => false},
				{:person_name => '', :person_email => '', :person_is_manager => false},
				{:person_name => '', :person_email => '', :person_is_manager => false},
			],
		}
		@errors = {}
		erb :signup
	end

	get '/*' do
		path = params[:splat].first
		viewname = path.sub(/\.html$/, '')
		if !File.exist?("views/#{viewname}.erb")
			return not_found
		end
		if path.match?(/\.html/)
			return redirect "/#{viewname}", 301
		end
		erb viewname.to_sym
	end

	not_found do
		erb :not_found
	end

	error do
		@error = env['sinatra.error']
		erb :error
	end

	helpers do

		def validate(k,v)
			case k
			when :person_name
				if v.nil? || v.empty?
					'Your name must not be blank'
				end
			when :department_name
				if v.nil? || v.empty?
					'Department name must not be blank'
				end
			when :service_name
				if v.nil? || v.empty?
					'Service name must not be blank'
				end
			when :person_email
				if v.nil? || v.empty?
					'Email address must not be blank'
				elsif !v.match?(/.+@.+/)
					'Must enter a valid email address'
				elsif !v.match?(/gov.uk$/)
					'We can only accept requests from govenment departments at this time'
				end
			end
		end

		# return comma seperated list of errors from validation if resourse has been validated
		def errors_for(resource, field)
			return nil if !resource.validated?
			errs = resource.errors[field]
			return nil if !errs or errs.size == 0
			return errs.join(", ")
		end

		# create a deskpro client
		def deskpro
			Deskpro::Client.new(
				api_key: ENV['DESKPRO_API_KEY'],
				endpoint: ENV['DESKPRO_ENDPOINT']
			)
		end

		# if google analytics tracking ids available send tracking event
		def track_event(action)
			if params['ga_tracking_id'] and params['ga_client_id']
				tracker = Staccato.tracker(params['ga_tracking_id'], params['ga_client_id'], ssl: true, document_hostname: params['ga_hostname'])
				tracker.event(category: 'support', action: action, value: 1)
			end
		end

	end

end
