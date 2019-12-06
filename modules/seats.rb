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
    things.each do |k, v|
      instance_variable_set("@#{k}", v)
      self.class.send(:attr_reader, k)
    end
  end

  def self.booked_seats(booking_id)
    execute 'SELECT * FROM seats_connector WHERE booking_id = ?', booking_id
  end

  def self.booked_seat(booking_id, service_id)
    self.new execute('SELECT * FROM seats_connector WHERE booking_id = ? AND service_id = ?', booking_id, service_id).first
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

  def self.reserve(amount, service_id, boocking_id)
    seats = get_empty_seats service_id
    reserved = []
    amount = amount.to_i
    return 'Did not select any seats' if amount == 0

    raise 'No available seats' if amount >= seats.length

    seats.each_with_index do |seat, i|
      break if i >= amount

      assign seat['id']
      reserved << seat['id']
      execute 'INSERT INTO seats_connector (seat_id, service_id, booking_id) VALUES (?,?,?)',
              seat['id'], service_id, boocking_id
    end
    reserved
  end

  def self.assign(seat_id)
    execute('UPDATE seats SET occupied = 1 WHERE id = ?', seat_id)
  end

  def self.de_assign(seat_id)
    execute('UPDATE seats SET occupied = 0 WHERE id = ?', seat_id)
  end
end
