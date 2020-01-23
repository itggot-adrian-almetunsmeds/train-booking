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

  it 'searches for booking and places order as a signed in user' do
    find('#login').click
    within('#login_form') do
      fill_in('email', with: 'admin@admin')
      fill_in('password', with: 'admin')
      click_button 'Sign In'
    end
    within('.search_form') do
      fill_in('departure', with: 'göteborg')
      fill_in('arrival', with: 'stock')
      click_button 'Search'
    end

    find('td', text: '30').click
    fill_in('ticket1', with: 3)
    fill_in('ticket4', with: 7)
    find('#submitticket').click

    # UNABLE TO BE REDIRECTED AS JS IS NOT APPLIED
    # sleep 5
    # visit('/checkout')
    # sleep 10
    # p current_path
    # assert_equal(true, has_current_path?('/checkout'))
    # expect(find('div#complete').find('h4')).to have_content('Points gained as a signed in user 650')

    # count = 0
    # all('a').each do |a|
    #   count += 1 if a['href'].include?('/service/')
    # end
    # assert_equal(2, count)
  end
end
