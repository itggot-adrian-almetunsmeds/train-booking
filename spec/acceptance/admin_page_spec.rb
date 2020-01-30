# frozen_string_literal: true

require_relative 'acceptance_helper'

class AdminPagegSpec < Minitest::Spec
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

  it 'Logs in as admin and checks the dashboard' do
    find('#login').click
    within('#login_form') do
      fill_in('email', with: 'admin@admin')
      fill_in('password', with: 'admin')
      click_button 'Sign In'
    end

    find('h4', text: 'Admin').click

    find('p', text: 'No bookings found')

    assert_equal(12, all('form').length)

    find('button', text: 'Create')
  end
end
