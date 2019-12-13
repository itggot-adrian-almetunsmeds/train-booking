# frozen_string_literal: true

require 'rspec'
require_relative '../modules/db_handler'
RSpec.describe 'DB Handler' do
  it 'Verifies sql queries' do
    expect(
      DBHandler.join_constructor(
        [:booking, potatis: [:pasta, potatismo: [:soffa]]], :bookings
      ).strip.downcase
    ).to eq 'LEFT JOIN booking ON bookings.booking_id = booking.id LEFT JOIN potatis ON bookings.potatis_id = potatis.id LEFT JOIN pasta ON potatis.pasta_id = pasta.id LEFT JOIN potatismo ON potatis.potatismo_id = potatismo.id LEFT JOIN soffa ON potatismo.soffa_id = soffa.id'.downcase
    expect(
      DBHandler.join_constructor(
        [:services, :korv, potatis: %i[ketchup batts]], :bookings
      ).strip.downcase
    ).to eq 'LEFT JOIN services ON bookings.services_id = services.id LEFT JOIN korv ON bookings.korv_id = korv.id LEFT JOIN potatis ON bookings.potatis_id = potatis.id LEFT JOIN ketchup ON potatis.ketchup_id = ketchup.id LEFT JOIN batts ON potatis.batts_id = batts.id'.downcase
    expect(
      DBHandler.select_constructor(
        ['bookings.id', 'things.id', 'else value'], :bookings
      ).strip.downcase
    ).to eq "SELECT bookings.id AS 'bookings.id', things.id AS 'things.id', else_value AS 'else_value' FROM bookings".downcase
    expect(
      DBHandler.select_constructor(
        ['bookings.id', 'things.id', 'elsevalue'], :bookings
      ).strip.downcase
    ).to eq "SELECT bookings.id AS 'bookings.id', things.id AS 'things.id', elsevalue AS 'elsevalue' FROM bookings".downcase
  end
end
