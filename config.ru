require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
configure do
	set :server, :puma
	set :protection, :except => :frame_options
end

require './app'
run App
