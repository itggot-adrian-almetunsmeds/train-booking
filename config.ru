# frozen_string_literal: true

require 'bundler'

Bundler.require

require_relative './server'

Dir['modules/**/*.rb'].each do |file|
  require_relative file
end

# Security settings
use Rack::Protection
use Rack::Protection::StrictTransport
use Rack::Protection::EscapedParams
use Rack::Protection::XSSHeader # For those still using Internet Explorer..
use Rack::Protection::RemoteReferrer
use Rack::Protection::FormToken
use Rack::Protection::AuthenticityToken

Rack::Server.start(
  Port: 9292,
  Host: '0.0.0.0',
  app: Server,
  SSLEnable: false
)
