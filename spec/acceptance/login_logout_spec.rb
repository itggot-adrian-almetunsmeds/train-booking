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

  it 'registers a user and signs in' do
    find('#login').click
    find('#login_form > a').click
    within('#register_form') do
      fill_in('first_name', with: 'Tester')
      fill_in('last_name', with: 'Tester')
      fill_in('email', with: 'Tester@Tester.com')
      fill_in('password', with: 'Tester')
      click_button 'Register'
    end

    page.must_have_css('#login > a > p')

    find('button', text: 'Sign Out').click
    find('#login').click

    within('#login_form') do
      fill_in('email', with: 'Tester@Tester.com')
      fill_in('password', with: 'tester')
      click_button 'Sign In'
    end

    assert_equal(false, page.has_css?('#login > a > p'))

    find('#login').click
    within('#login_form') do
      fill_in('email', with: 'Tester@Tester.com')
      fill_in('password', with: 'Tester')
      click_button 'Sign In'
    end
    page.must_have_css('#login > a > p')
  end
end
