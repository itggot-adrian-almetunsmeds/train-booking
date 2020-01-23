# frozen_string_literal: true

require_relative 'acceptance_helper'

class SearchBookinsgSpec < Minitest::Spec
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

  it 'searches for booking' do
    within('.search_form') do
      fill_in('departure', with: 'göteborg')
      fill_in('arrival', with: 'stock')
      click_button 'Search'
    end
    count = 0
    all('a').each do |a|
      count += 1 if a['href'].include?('/service/')
    end
    assert_equal(2, count)
  end

  it 'searches for booking' do
    within('.search_form') do
      fill_in('departure', with: ' ')
      fill_in('arrival', with: '')
      click_button 'Search'
    end
    count = 0
    all('a').each do |a|
      count += 1 if a['href'].include?('/service/')
    end
    assert_equal(4, count)
  end

  it 'searches for booking' do
    within('.search_form') do
      fill_in('departure', with: 'göteborg')
      fill_in('arrival', with: 'bro')
      click_button 'Search'
    end
    count = 0
    all('a').each do |a|
      count += 1 if a['href'].include?('/service/')
    end
    assert_equal(2, count)
  end
end
