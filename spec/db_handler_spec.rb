# frozen_string_literal: true

require 'rspec'
require_relative '../modules/db_handler'
require_relative '../db/seeder.rb'

RSpec.describe 'DBHandler:' do # rubocop:disable Metrics/BlockLength
  Seeder.seed!
  context 'When testing the DBHandler class' do # rubocop:disable Metrics/BlockLength
    handler = DBHandler.new
    p handler

    it 'the DBHandler object should have instance variables defined' do
      expect(
        handler.table.to_s
      ).to eq 'DBHandler'

      expect(
        handler.tables
      ).to eq nil

      handler.tables = 'potatis'
      expect(
        handler.tables
      ).to eq 'potatis'

      handler.tables = [potis: [:moserade, 'computer', apples: ['potatis']]]
      expect(
        handler.tables
      ).to eq [potis: [:moserade, 'computer', apples: ['potatis']]]

      expect(handler.has_many([potis: [:moserade, 'computer', apples: ['potatis']]])).to eq [[potis:
        [:moserade, 'computer', apples: ['potatis']]]]

      expect(handler.has_many('potatisar')).to eq ['potatisar']
    end

    handler = DBHandler.new
    it 'the select construcotr should reuturn the correct select query' do
      # Selects
      expect(
        handler.send(:select_constructor,
                     ['bookings.id', 'things.id', 'else value'], :bookings).strip.downcase
      ).to eq "SELECT bookings.id AS 'bookings.id', things.id AS 'things.id', else_value AS".downcase +
              " 'else_value' FROM bookings".downcase

      expect(
        handler.send(:select_constructor,
                     'things', :bookings).strip.downcase
      ).to eq 'SELECT things FROM bookings'.downcase

      expect(
        handler.send(:select_constructor,
                     :things, :bookings).strip.downcase
      ).to eq 'SELECT things FROM bookings'.downcase

      expect(
        handler.send(:select_constructor,
                     %i[things orwhat], :bookings).strip.downcase
      ).to eq "SELECT things as 'things', orwhat as 'orwhat' FROM bookings".downcase

      expect(
        handler.send(:select_constructor,
                     %w[things or], :bookings).strip.downcase
      ).to eq "SELECT things AS 'things', or AS 'or' FROM bookings".downcase

      expect(
        handler.send(:select_constructor,
                     ['bookings.id', 'things.id', 'elsevalue'], :bookings).strip.downcase
      ).to eq "SELECT bookings.id AS 'bookings.id', things.id AS 'things.id', elsevalue AS ".downcase +
              "'elsevalue' FROM bookings".downcase
    end

    handler = DBHandler.new
    it 'the join constructor should return correct joins' do
      # Joins
      expect(
        handler.send(:join_constructor,
                     [:booking, potatis: [:pasta, potatismo: [:soffa]]], :bookings).strip.downcase
      ).to eq 'LEFT JOIN booking ON bookings.booking_id = booking.id LEFT JOIN potatis ON '.downcase +
              'bookings.potatis_id = potatis.id LEFT JOIN pasta ON potatis.pasta_id ='.downcase +
              ' pasta.id LEFT JOIN potatismo ON potatis.potatismo_id = potatismo.id '.downcase +
              'LEFT JOIN soffa ON potatismo.soffa_id = soffa.id'.downcase

      expect(
        handler.send(:join_constructor,
                     [:services, :korv, potatis: %i[ketchup batts]], :bookings).strip.downcase
      ).to eq 'LEFT JOIN services ON bookings.services_id = services.id LEFT JOIN korv ON '.downcase +
              'bookings.korv_id = korv.id LEFT JOIN potatis ON bookings.potatis_id = '.downcase +
              'potatis.id LEFT JOIN ketchup ON'.downcase +
              ' potatis.ketchup_id = ketchup.id LEFT JOIN batts ON '.downcase +
              'potatis.batts_id = batts.id'.downcase

      expect(
        handler.send(:join_constructor,
                     :services, :bookings).strip.downcase
      ).to eq 'LEFT JOIN services ON bookings.services_id = services.id'.downcase

      expect(
        handler.send(:join_constructor,
                     :service_connector, :bookings).strip.downcase
      ).to eq 'LEFT JOIN service_connector ON bookings.id = service_connector.bookings_id'.downcase
    end

    handler = DBHandler.new
    it 'the where constructor should return a correct sql query and the values associated' do
      # Wheres
      expect(
        handler.send(:where_constructor,
                     %w[bookings=12 things=11 elsevalue=null])
      ).to eq [' WHERE bookings = ? AND things = ? AND elsevalue = ?', %w[12 11 null]]

      expect(
        handler.send(:where_constructor,
                     ['mos = pasta', 'pasta = present'])
      ).to eq [' WHERE mos  = ? AND pasta  = ?', [' pasta', ' present']]

      expect(
        handler.send(:where_constructor,
                     user: 'some', pasta: true)
      ).to eq [' WHERE  user = ? AND pasta = ?', ['some', true]]

      expect(
        handler.send(:where_constructor,
                     user: %w[some things], pasta: true)
      ).to eq [' WHERE  user IN (?,?) AND pasta = ?', ['some', 'things', true]]

      expect(
        handler.send(:where_constructor,
                     user: %w[some things], pasta: :decorations)
      ).to eq [' WHERE  user IN (?,?) AND pasta = ?', %w[some things decorations]]
    end

    handler = DBHandler.new
    it 'the order construtor should return the correct sql query' do
      # Order
      expect { handler.send(:order_constructor, '') }.to raise_error(RuntimeError)

      expect { handler.send(:order_constructor, things: 'asdas') }.to raise_error(RuntimeError)

      expect { handler.send(:order_constructor, {}) }.to raise_error(RuntimeError)

      expect(handler.send(:order_constructor,
                          table: 'potatis').downcase.strip).to eq 'order by potatis'.downcase

      expect(handler.send(:order_constructor,
                          table: 'potatis',
                          order: 'DESC').downcase.strip).to eq 'order by potatis DESC'.downcase

      expect(handler.send(:order_constructor,
                          order: 'DESC').downcase.strip).to eq 'order by id DESC'.downcase
    end

    handler = DBHandler.new
    it 'Validate Table Input should validate the input' do
      # Validate Table Input
      expect do
        handler.send(:validate_table_input, [[[[%w[potatsi mos]]]]])
      end.to raise_error(RuntimeError)

      expect { handler.send(:validate_table_input, {}) }.to raise_error(RuntimeError)

      expect { handler.send(:validate_table_input, rhinfs: 'potatsi') }.to raise_error(RuntimeError)

      expect(handler.send(:validate_table_input, [[[['mos']]]])).to eq 'mos'

      expect(handler.send(:validate_table_input, [[[[:mos]]]])).to eq 'mos'

      expect(handler.send(:validate_table_input, 'potatis')).to eq 'potatis'

      expect(handler.send(:validate_table_input, :mos)).to eq 'mos'
    end
  end
end
