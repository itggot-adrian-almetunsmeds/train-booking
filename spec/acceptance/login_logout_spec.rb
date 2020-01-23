# frozen_string_literal: true

require_relative 'acceptance_helper'

class LoginLogoutSpec < Minitest::Spec
  include ::Capybara::DSL
  include ::Capybara::Minitest::Assertions

  def self.test_order
    :alpha # run the tests in this file in order
  end

  before do
    visit '/'
  end

  after do
    Capybara.reset_sessions!
  end

  it 'user login and log out' do
    find('#login').click
    within('#login_form') do
      fill_in('email', with: 'admin@admin')
      fill_in('password', with: 'admin')
      click_button 'Sign In'
    end

    find('button', text: 'Sign Out').click
  end
end
