require 'rest-client'

##
# Deskpro REST client and resources
#
# This module allows interacting with the Deskpro REST api v1.
#
# ----------------------------------------
# :section: General Usage
# client = Deskpro::Client.new(api_key: "YOUR_KEY", endpoint: "https://youraccount.deskpro.com")
# ticket = Deskpro::Ticket.new(subject: "Help", message: "I need help", person_email: "test@localhost.local")
# client.post(ticket)
# puts(ticket.id)
# ----------------------------------------
 
module Deskpro

	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
	MAX_FIELD_LEN = 2048

	# The DeskproClient is a wrapper around the deskpro REST API
	class Client

		def initialize(api_key:, endpoint:)
			if !endpoint or endpoint.empty?
				raise Deskpro::Error, "invalid endpoint"
			end
			if !api_key or api_key.empty?
				raise Deskpro::Error, "api_key is required"
			end
			@api_key = api_key
			@endpoint = "#{endpoint}/api"
			@options = {
				read_timeout: 10,
				headers: {
					"X-DeskPRO-API-Key" => api_key,
					"Accept-Encoding" => "*",
					:content_type => :json,
					:accept => :json,
				},
			}
		end

		def post(record)
			if !record.kind_of? Resource
				raise ArgumentError, "cannot post a #{record.class.name} expected a Deskpro::Resource"
			end
			if !record.valid?
				raise ValidationError, record.errors.inject([]){|all, (_name, errs)| all << errs}.join(", ")
			end
			resource = RestClient::Resource.new("#{@endpoint}#{record.class.endpoint}", @options)
			res = resource.post(record.values.to_json)
			code = res.code
			body = res.body
			if code != 201
				raise BadResponse, "non 201 response: code:#{code} body:#{body}"
			end
			data = JSON.parse(body)
			if !data['ticket_id']
				raise BadResponse, "expected to get a ticket_id back from POST"
			end
			record.id = data['ticket_id']
		end

	end

	# Resource is a base class for modeling and validating resources
	class Resource

		@fields = {}
		@endpoint = ''

		# path is a helper for defining the endpoint of the resource
		def self.path(path)
			@endpoint = path
		end

		# endpoint returns the relative path for the REST resource
		def self.endpoint
			@endpoint
		end

		# field is a helper for declaring what fields are valid for the resource
		def self.field(name, type, **opts)
			opts[:type] = type
			@fields ||= {}
			@fields[name.to_s] = opts
			define_method("#{name}") do
				@values["#{name}"]
			end
			define_method("#{name}=") do |value|
				@values["#{name}"] = value
			end
		end

		# fields returns all the field definitions set for the resource
		def self.fields
			@fields
		end

		# create an instance of the resource. field values can be passed as kwargs or hash
		def initialize(vargs = {}, **kwargs)
			values = vargs.merge(kwargs).inject({}) do |args, (name, value)|
				if !self.class.fields.has_key?(name.to_s)
					raise ArgumentError, "#{self.class.name} does not have a field called '#{name}'"
				end
				args[name.to_s] = value
				args
			end
			@validated = false
			@values = {}
			self.class.fields.each do |name, opts|
				if values.has_key?(name)
					send("#{name}=", values[name])
				end
			end
		end

		# values returns any currently set field values
		def values
			self.class.fields.inject({}) do |values, (name, _opts)|
				values[name.to_sym] = @values[name] if @values.has_key? name
				values
			end
		end

		# valid? returns false if any of the fields contain invalid data
		def valid?
			errors.size == 0
		end

		# returns true if validate has been called
		def validated?
			return !!@validated
		end

		# errors returns a hash of errors {:field_name => [err1, err2]}
		def errors
			validate.inject({}) do |h, err|
				k = err[:name].to_sym
				h[k] ||= []
				h[k] << err[:message]
				h
			end
		end

		protected

		# validate returns a list of validation errors.
		def validate
			@validated = true
			self.class.fields.inject([]) do |errs, (name, opts)|
				if @values.has_key?(name)
					value = @values[name]
					if !value.kind_of? opts[:type]
						errs.push({name: name, message: "expected type #{opts[:type]} got #{value.class.name}"})
					elsif opts[:type] == String
						if opts[:required] and !value
							errs.push({name: name, message: "required field cannot be empty"})
						elsif opts.has_key?(:min) and value.size < opts[:min]
							errs.push({name: name, message: "require at least #{opts[:min]} characters"})
						elsif opts.has_key?(:max) and value.size > opts[:max] 
							errs.push({name: name, message: "max length of text is #{opts[:max]} characters"})
						elsif opts.has_key?(:match) and !opts[:match].match?(value)
							errs.push({name: name, message: "invalid"})
						end
					elsif opts[:type] == Array
						if opts[:of]
							if !value.all?{|v| v.kind_of?(opts[:of]) }
								errs.push({name: name, message: "expected all elements to be #{opts[:of]}"})
							end
						end
					else
						if opts.has_key?(:min) and value < opts[:min]
							errs.push({name: name, message: "must be at least #{opts[:min]}"})
						elsif opts.has_key?(:max) and value > opts[:max] 
							errs.push({name: name, message: "must be at most #{opts[:max]}"})
						end
					end
				else
					errs.push({name: name, message: 'required'}) if opts[:required]
				end
				errs
			end
		end

	end

	# Ticket is model for creating tickets
	class Ticket < Resource
		path '/tickets'
		field :id,                           Integer, :min => 1
		field :person_id,                    Integer
		field :person_email,                 String, :required => true, :match => VALID_EMAIL_REGEX, :min => 5, :max => MAX_FIELD_LEN
		field :person_name,                  String, :required => true, :min => 2, :max => MAX_FIELD_LEN
		field :person_organization,          String
		field :person_organization_position, String
		field :subject,                      String, :required => true, :max => MAX_FIELD_LEN, :min => 1
		field :message,                      String, :required => true, :max => MAX_FIELD_LEN, :min => 1
		field :message_as_agent,             Integer, :min => 0, :max => 1
		field :message_is_html,              Integer, :min => 0, :max => 1
		field :agent_id,                     Integer
		field :agent_team_id,                Integer
		field :category_id,                  Integer
		field :department_id,                Integer
		field :label,                        Array, :of => String
		field :language_id,                  Integer
		field :priority_id,                  Integer
		field :product_id,                   Integer
		field :status,                       String, :match => /awaiting_user|awaiting_agent|closed|hidden|resolved/
		field :sla_id,                       Array, :of => String
		field :urgency,                      Integer, :min => 1, :max => 10
		field :workflow_id,                  Integer, :min => 1
	end

	# DeskproError is the superclass for all errors in this class
	class Error < StandardError; end

	# DeskproValidationError is raised when field validation fails
	class ValidationError < Deskpro::Error; end

	# DeskproBadResponse is raised when a non 200 response is returned
	class BadResponse < Deskpro::Error; end

end
