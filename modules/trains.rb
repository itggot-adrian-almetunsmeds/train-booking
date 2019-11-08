# frozen_string_literal: true

require_relative 'db_handler'

class Trains
  def self.initialize; end

  def self.all
    DBHandler.execute('SELECT * FROM trains')
  end
end

Trains.all
