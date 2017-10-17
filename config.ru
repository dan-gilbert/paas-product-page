require 'rubygems'
require 'bundler'

Bundler.require

if ENV['SESSION_SECRET'].nil? or ENV['SESSION_SECRET'].empty?
	puts "WARNING: No session secret has been set. You should set the SESSION_SECRET environment variable to a secure random secret. Using a randomly generated secret for now which is fine for development but not for production"
	require 'sysrandom/securerandom'
	ENV['SESSION_SECRET'] = SecureRandom.hex(64)
end

require 'sinatra'
configure do
	set :server, :puma
end

require './app'
run App
