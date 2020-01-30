# frozen_string_literal: true

require 'capybara/minitest'
require 'capybara/minitest/spec'
require 'rack/test'

require_relative '../spec_helper'
require_relative '../../server.rb'

Capybara.app = Server

Capybara.default_driver = :selenium_chrome_headless

# Registers thin as the webserver
Capybara.register_server :thin do |app, port, host|
  require 'rack/handler/thin'
  Rack::Handler::Thin.run(app, Port: port, Host: host)
end

Capybara.server = :thin
