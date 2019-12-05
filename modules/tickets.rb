# frozen_string_literal: true

require_relative 'db_handler'

# Handles everything relating to tickets
class Ticket
  attr_reader :name, :price, :total_points, :points, :total_price, :amount

  def initialize(ticket_id, amount = 1)
    data = DBHandler.with_id('tickets', ticket_id)
    @name = data['name']
    @price = data['price']
    @total_price = data['price'].to_i * amount
    @points = data['points']
    @total_points = data['points'].to_i * amount
    @amount = amount
  end
end
