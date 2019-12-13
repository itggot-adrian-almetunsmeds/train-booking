# frozen_string_literal: true

require_relative 'db_handler'

class Objects
  def self.merge(from, to)
    from.instance_variables.map { |v| to.instance_variable_set(v, from.instance_variable_get(v)) }
    to
  end
end

class Seat < DBHandler
  def initialize(things)
    things.each do |k|
      k.each do |s, v|
        if !instance_variable_get("@#{s}").nil?
          value = instance_variable_get("@#{s}")
          if value.is_a? Array
            value << v
          else
            value = [value, v] unless value == v
          end
          instance_variable_set("@#{s}", value)
        else
          instance_variable_set("@#{s}", v)
        end
        self.class.send(:attr_reader, s.to_sym)
      end
    end
  end

  def self.booked_seats(booking_id)
    seats_hash = execute 'SELECT * FROM seats_connector WHERE booking_id = ?', booking_id
    seats_array = []
    seats_hash.each do |k|
      seats_array << k
      p 'This is k'
      p k
    end
    new seats_array
  end

  def self.booked_seats_ticket(booking_id, ticket_id)
    seats_hash = execute 'SELECT * FROM seats_connector WHERE booking_id = ? AND ticket_id = ?', booking_id, ticket_id
    seats_array = []
    seats_hash.each do |k|
      seats_array << k
    end
    new seats_array
  end

  def self.booked_seat(booking_id, service_id)
    x = execute('SELECT * FROM seats_connector WHERE booking_id = ? AND service_id = ?', booking_id, service_id)
    # p x
    new x
  end

  def self.fetch(id)
    with_id 'seats', id
  end

  def self.get_empty_seats(service_id)
    execute 'SELECT * FROM seats WHERE occupied = 0 AND service_id = ?', service_id.to_i
  end

  def self.get_occupied_seats(service_id)
    execute 'SELECT * FROM seats WHERE occupied = 1 AND service_id = ?', service_id
  end

  def self.empty_seats?(_service_id)
    execute('SELECT COUNT(id) FROM seats WHERE occupied = 0').first ? true : false
  end

  def self.reserve(amount, service_id, boocking_id, ticket_id)
    seats = get_empty_seats service_id
    reserved = []
    amount = amount.to_i
    return 'Did not select any seats' if amount == 0

    raise 'No available seats' if amount >= seats.length

    seats.each_with_index do |seat, i|
      break if i >= amount

      assign seat['id']
      reserved << seat['id']
      execute 'INSERT INTO seats_connector (seat_id, service_id, booking_id, ticket_id) VALUES (?,?,?,?)',
              seat['id'], service_id, boocking_id, ticket_id
    end
    Service.update_empty_seats service_id
    reserved
  end

  def self.assign(seat_id)
    execute('UPDATE seats SET occupied = 1 WHERE id = ?', seat_id)
  end

  def self.de_assign(seat_id)
    execute('UPDATE seats SET occupied = 0 WHERE id = ?', seat_id)
  end
end
