require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'sinatra/multi_route'
require 'staccato'
require 'sprockets'
require 'sprockets-helpers'

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

	after do
		headers 'X-Robots-Tag' => 'noindex, nofollow' #FIXME
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

	route :get, :post, '/request-account' do
		puts "params: #{params}"
		set_from_param(:person_name)
		set_from_param(:person_email)
		set_from_param(:person_is_manager)
		set_from_param(:department_name)
		set_from_param(:service_name)
		(params[:invites] || {}).each do |k,v|
			invs = session[:invites] ||= {}
			invs ||= {}
			invs[k] = v
			invs[k][:idx] = k.to_i
		end
		puts "session: #{session.to_h}"
		if params[:continue] == 'false'
			erb :thanks
		else
			erb :'request-account'
		end
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

		# the current session account details
		def account
			session[:account] ||= {}
		end

		# the current active invite from session
		def invite
			invites = session[:invites] ||= {}
			idx = (params[:invite] || '0')
			invites[idx] ||= {:idx => idx.to_i}
		end

		def has_next_invite?
			idx = (params[:invite] || '0').to_i+1
			invites = session[:invites] ||= {}
			invites.has_key? idx.to_s
		end

		def set_from_param(name)
			if params[name].is_a?(String) && !params[name].empty?
				account[name] = params[name]
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
