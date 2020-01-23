# frozen_string_literal: true

require_relative 'db_handler'

class Objects
  def self.merge(from, to)
    from.instance_variables.map { |v| to.instance_variable_set(v, from.instance_variable_get(v)) }
    to
  end
end

class Seat_connector < DBHandler
  set_table :seat_connector
  set_columns :seat_id, :service_id, :booking_id, :ticket_id
end

class Seat < DBHandler
  set_table :seat
  set_columns :id, :service_id, :occupied, :booking_id
  # has_a :service

  def self.booked_seats(booking_id)
    seats_hash = execute 'SELECT * FROM seats_connector WHERE booking_id = ?', booking_id
    seats_array = []
    seats_hash.each do |k|
      seats_array << k
    end
    new seats_array
  end

  def self.fetch(id)
    with_id 'seats', id
  end

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
