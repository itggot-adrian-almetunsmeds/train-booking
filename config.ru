# frozen_string_literal: true

require 'bundler'

Bundler.require

require_relative './server'

Dir['modules/**/*.rb'].each do |file|
  require_relative file
end

Rack::Server.start(
  Port: 9292,
  Host: '0.0.0.0',
  app: Server,
  SSLEnable: false
)
