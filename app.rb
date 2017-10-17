require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'staccato'
require 'sprockets'
require 'sprockets-helpers'

require './models/deskpro'

# App is the main Sinatra application
class App < Sinatra::Base

	set :sprockets, Sprockets::Environment.new
	set :title, 'Gov.UK Platform as a Service'

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
	end

	helpers Sinatra::ContentFor
	helpers Sprockets::Helpers

	after do
		headers 'X-Robots-Tag' => 'noindex, nofollow'
	end

	get '/?' do
		erb :index
	end

	get '/register' do
		@ticket = Deskpro::Ticket.new
		erb :register
	end

	post '/register' do
		@ticket = Deskpro::Ticket.new({
			subject: "#{Date.today.to_s} New user registration",
			message: "#{params['person_name']} would like to request an account",
			person_email: params['person_email'],
			person_name: params['person_name'],
			label: ['paas'],
		})
		@ticket.agent_team_id = ENV['DESKPRO_TEAM_ID'].to_i if ENV['DESKPRO_TEAM_ID']
		if not @ticket.valid?
			status 400
			erb :register
		else
			deskpro.post @ticket
			track_event 'register'
			erb :thanks
		end
	end

	get '/support' do
		@ticket = Deskpro::Ticket.new
		erb :support
	end

	post '/support' do
		@ticket = Deskpro::Ticket.new({
			subject: "#{Date.today.to_s} Support Request From Website",
			person_email: params['person_email'],
			person_name: params['person_name'],
			message: params['message'],
			label: ['paas'],
		})
		@ticket.agent_team_id = ENV['DESKPRO_TEAM_ID'].to_i if ENV['DESKPRO_TEAM_ID']
		if not @ticket.valid?
			status 400
			erb :support
		else
			deskpro.post @ticket
			track_event 'enquire'
			erb :thanks
		end
	end

	get "/assets/*" do
		env["PATH_INFO"].sub!("/assets", "")
		settings.sprockets.call(env)
	end

	get '/*' do
		viewname = params[:splat].first
		if File.exist?("views/#{viewname}.erb")
			erb viewname.to_sym
		else
			not_found
		end
	end

	not_found do
		erb :not_found
	end

	error do
		@error = env['sinatra.error']
		erb :error
	end

	helpers do


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
