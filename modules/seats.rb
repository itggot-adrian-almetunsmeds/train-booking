# frozen_string_literal: true

require_relative 'db_handler'

# Configures seat connector
class Seat_connector < DBHandler # rubocop:disable Naming/ClassAndModuleCamelCase
  set_table :seat_connector
  set_columns :seat_id, :service_id, :booking_id, :ticket_id
end

# Handles seats
class Seat < DBHandler
  set_table :seat
  set_columns :id, :service_id, :occupied, :booking_id

  # Reserves seats
  #
  # amount - Amount of seats to reserve (Integer)
  # service_id - Service id (Integer)
  # boocking_id - Booking id (Integer)
  #
  # ticket_id - Ticket id (Integer)
  #
  # Returns reserved seats (Objects) in an array
  def self.reserve(amount, service_id, boocking_id, ticket_id)
    seats = Seat.fetch_where service_id: service_id, occupied: 0
    raise 'Did not select any seats' if seats == []

    reserved = []
    if seats.is_a? Array
      raise 'No available seats' if seats.length < amount.to_i

      seats.each_with_index do |seat, index|
        next if index >= amount.to_i

        seat.occupied = 1
        seat.booking_id = boocking_id
        temp = Seat_connector.new(seat_id: seat.id, service_id: service_id,
                                  booking_id: boocking_id, ticket_id: ticket_id)
        temp.save
        seat.save
        reserved << seat
      end
    end

    Service.update_empty_seats service_id
    reserved
  end
end
