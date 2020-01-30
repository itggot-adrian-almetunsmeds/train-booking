# frozen_string_literal: true

require 'rspec'
require_relative '../../modules/db_handler'
require_relative '../../db/seeder.rb'

class Temp < DBHandler
end

RSpec.describe 'DBHandler:' do # rubocop:disable Metrics/BlockLength
  Seeder.seed!
  context 'When testing the DBHandler class' do # rubocop:disable Metrics/BlockLength
    it 'the DBHandler object should have instance variables defined' do
      expect(
        Temp.table.to_s
      ).to eq ''

      expect(
        Temp.tables
      ).to eq nil

      handler = Temp.new id: 92
      expect(
        handler.id
      ).to eq 92

      class Temp2 < DBHandler
        set_table :potatis
        has_a [potis: [:moserade, 'computer', apples: ['potatis']]]
      end

      expect(
        Temp2.table.to_s
      ).to eq 'potatis'

      expect(
        Temp2.tables
      ).to eq [[potis: [:moserade, 'computer', apples: ['potatis']]]]
    end

    it 'the select construcotr should reuturn the correct select query' do
      # Selects
      expect(
        DBHandler.send(:select_constructor,
                       ['bookings.id', 'things.id', 'else value'], :bookings).strip.downcase
      ).to eq "SELECT bookings.id AS 'bookings.id', things.id AS 'things.id', else_value AS".downcase +
              " 'else_value' FROM bookings".downcase

      expect(
        DBHandler.send(:select_constructor,
                       'things', :bookings).strip.downcase
      ).to eq 'SELECT things FROM bookings'.downcase

      expect(
        DBHandler.send(:select_constructor,
                       :things, :bookings).strip.downcase
      ).to eq 'SELECT things FROM bookings'.downcase

      expect(
        DBHandler.send(:select_constructor,
                       %i[things orwhat], :bookings).strip.downcase
      ).to eq "SELECT things as 'things', orwhat as 'orwhat' FROM bookings".downcase

      expect(
        DBHandler.send(:select_constructor,
                       %w[things or], :bookings).strip.downcase
      ).to eq "SELECT things AS 'things', or AS 'or' FROM bookings".downcase

      expect(
        DBHandler.send(:select_constructor,
                       ['bookings.id', 'things.id', 'elsevalue'], :bookings).strip.downcase
      ).to eq "SELECT bookings.id AS 'bookings.id', things.id AS 'things.id', elsevalue AS ".downcase +
              "'elsevalue' FROM bookings".downcase
    end

    # handler = DBHandler.new
    it 'the join constructor should return correct joins' do
      # Joins
      expect(
        DBHandler.send(:join_constructor,
                       [:booking, potatis: [:pasta, potatismo: [:soffa]]], :bookings).strip.downcase
      ).to eq 'LEFT JOIN booking ON bookings.booking_id = booking.id LEFT JOIN potatis ON '.downcase +
              'bookings.potatis_id = potatis.id LEFT JOIN pasta ON potatis.pasta_id ='.downcase +
              ' pasta.id LEFT JOIN potatismo ON potatis.potatismo_id = potatismo.id '.downcase +
              'LEFT JOIN soffa ON potatismo.soffa_id = soffa.id'.downcase

      expect(
        DBHandler.send(:join_constructor,
                       [:services, :korv, potatis: %i[ketchup batts]], :bookings).strip.downcase
      ).to eq 'LEFT JOIN services ON bookings.services_id = services.id LEFT JOIN korv ON '.downcase +
              'bookings.korv_id = korv.id LEFT JOIN potatis ON bookings.potatis_id = '.downcase +
              'potatis.id LEFT JOIN ketchup ON'.downcase +
              ' potatis.ketchup_id = ketchup.id LEFT JOIN batts ON '.downcase +
              'potatis.batts_id = batts.id'.downcase

      expect(
        DBHandler.send(:join_constructor,
                       :services, :bookings).strip.downcase
      ).to eq 'LEFT JOIN services ON bookings.services_id = services.id'.downcase

      expect(
        DBHandler.send(:join_constructor,
                       :service_connector, :bookings).strip.downcase
      ).to eq 'LEFT JOIN service_connector ON bookings.id = service_connector.bookings_id'.downcase
    end

    # handler = DBHandler.new
    it 'the where constructor should return a correct sql query and the values associated' do
      # Wheres
      expect(
        DBHandler.send(:where_constructor,
                       ['bookings = 12', 'things = 11', 'elsevalue = null'], nil)
      ).to eq [' WHERE bookings = ? AND things = ? AND elsevalue = ?', %w[12 11 null]]

      expect(
        DBHandler.send(:where_constructor,
                       ['mos = pasta', 'pasta = present'], nil)
      ).to eq [' WHERE mos = ? AND pasta = ?', %w[pasta present]]

      expect(
        DBHandler.send(:where_constructor,
                       [user: 'some', pasta: true], nil)
      ).to eq [' WHERE  user = ? AND pasta = ?', ['some', true]]
      expect(
        DBHandler.send(:where_constructor,
                       [id: 23, pasta: true], :user)
      ).to eq [' WHERE  user.id = ? AND pasta = ?', [23, true]]

      expect(
        DBHandler.send(:where_constructor,
                       [user: %w[some things], pasta: true], nil)
      ).to eq [' WHERE  user IN (?,?) AND pasta = ?', ['some', 'things', true]]

      expect(
        DBHandler.send(:where_constructor,
                       [user: %w[some things], pasta: :decorations], nil)
      ).to eq [' WHERE  user IN (?,?) AND pasta = ?', %w[some things decorations]]
    end

    # handler = DBHandler.new
    it 'the order construtor should return the correct sql query' do
      # Order
      expect { DBHandler.send(:order_constructor, '') }.to raise_error(RuntimeError)

      expect { DBHandler.send(:order_constructor, things: 'asdas') }.to raise_error(RuntimeError)

      expect { DBHandler.send(:order_constructor, {}) }.to raise_error(RuntimeError)

      expect(DBHandler.send(:order_constructor,
                            table: 'potatis').downcase.strip).to eq 'order by potatis'.downcase

      expect(DBHandler.send(:order_constructor,
                            table: 'potatis',
                            order: 'DESC').downcase.strip).to eq 'order by potatis DESC'.downcase

      expect(DBHandler.send(:order_constructor,
                            order: 'DESC').downcase.strip).to eq 'order by id DESC'.downcase
    end

    # handler = DBHandler.new
    it 'Validate Table Input should validate the input' do
      # Validate Table Input
      expect do
        DBHandler.send(:validate_table_input, [[[[%w[potatsi mos]]]]])
      end.to raise_error(RuntimeError)

      expect { DBHandler.send(:validate_table_input, {}) }.to raise_error(RuntimeError)

      expect { DBHandler.send(:validate_table_input, rhinfs: 'potatsi') }.to raise_error(RuntimeError)

      expect(DBHandler.send(:validate_table_input, [[[['mos']]]])).to eq 'mos'

      expect(DBHandler.send(:validate_table_input, [[[[:mos]]]])).to eq 'mos'

      expect(DBHandler.send(:validate_table_input, 'potatis')).to eq 'potatis'

      expect(DBHandler.send(:validate_table_input, :mos)).to eq 'mos'
    end
  end
end
