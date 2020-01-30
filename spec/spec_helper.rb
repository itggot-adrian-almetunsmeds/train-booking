# frozen_string_literal: true

require 'bundler'

Bundler.setup
Bundler.require

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/reporters'

MiniTest::Reporters.use!(MiniTest::Reporters::SpecReporter.new)

class MiniTest::Spec # rubocop:disable Style/ClassAndModuleChildren
  include Rack::Test::Methods
end
