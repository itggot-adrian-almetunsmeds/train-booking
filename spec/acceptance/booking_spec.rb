# frozen_string_literal: true

require_relative 'acceptance_helper'

class BookingSpec < Minitest::Spec
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

  it 'checks redirects' do
    visit '/booking-complete'
    assert_equal(true, has_current_path?('/'))
    visit '/admin'
    assert_equal(true, has_current_path?('/'))
    visit '/user/1/edit'
    assert_equal(true, has_current_path?('/'))
    visit '/user/2'
    assert_equal(true, has_current_path?('/'))
    visit '/checkout'
    assert_equal(true, has_current_path?('/'))
  end

  it 'Creates a booking and checks that it excists' do
    find('#login').click
    within('#login_form') do
      fill_in('email', with: 'admin@admin')
      fill_in('password', with: 'admin')
      click_button 'Sign In'
    end

    find('h4', text: 'Admin').click

    within('#insert') do
      fill_in('name', with: 'This is a test')
      fill_in('train_id', with: '2')
      fill_in('departure_id', with: '3')
      fill_in('arrival_id', with: '2')
      fill_in('arrival_id', with: '2')
      fill_in('first', with: '1')
      fill_in('second', with: '2')
      fill_in('third', with: '3')
      fill_in('departure_time', with: '2080-05-20T04:00')
      fill_in('arrival_time', with: '2100-05-20T04:00')
      click_button 'Create'
    end

    has_selector?('h4', text: '5 - This is a test')
  end
end
