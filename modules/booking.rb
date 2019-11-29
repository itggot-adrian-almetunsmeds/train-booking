# frozen_string_literal: true

require_relative 'db_handler'
require_relative 'tickets'

class Booking
  attr_reader :user_id, :departure_location, :departure_track, :arrival_location, :departure_location, :arrival_track,
              :ticket_name, :total_price, :departure_time, :arrival_time, :total_points, :tickets, :booking_id

  attr_writer :total_price

  def initialize(session_id)
    data = DBHandler.execute(
      'SELECT bookings.id, user_id, departure.name AS departure_location, arrival.name AS arrival_location,'\
      ' dep.name AS departure_platform, arr.name AS arrival_platform, tickets.name AS ticket_name,'\
      ' arrival_time, departure_time, points, amount, tickets.id AS ticket_id,'\
      ' bookings.price as booking_price'\
      ' FROM bookings'\
      ' LEFT JOIN booking_connector'\
      ' ON bookings.id = booking_connector.booking_id'\
      ' LEFT JOIN tickets'\
      ' ON booking_connector.ticket_id = tickets.id'\
      ' LEFT JOIN services'\
      ' ON bookings.service_id = services.id'\
      ' LEFT JOIN platforms AS dep'\
      ' ON services.departure_id = dep.id'\
      ' LEFT JOIN platforms AS arr'\
      ' ON services.arrival_id = arr.id'\
      ' LEFT JOIN destinations as arrival'\
      ' ON arr.destination_id = arrival.id'\
      ' LEFT JOIN destinations as departure'\
      ' ON dep.destination_id = departure.id'\
      ' WHERE session_id = ?', session_id
    )
    @tickets = []
    @total_price = 0
    @total_points = 0
    data.each do |z|
      ticket = Ticket.new(z['ticket_id'], z['amount'])
      tickets << ticket
      @total_points += ticket.total_points
      @total_price += ticket.total_price
    end

    p tickets

    data = data.first
    @booking_id = data['id']
    @user_id = data['user_id']
    @departure_location = data['departure_location']
    @departure_track = data['departure_platform']
    @arrival_location = data['arrival_location']
    @arrival_track = data['arrival_platform']
    @departure_time = DateTime.strptime(data['departure_time'], '%s')
    @arrival_time = DateTime.strptime(data['arrival_time'], '%s')
  end

  def confirm
    DBHandler.execute('UPDATE bookings SET status = 1, session_id = ? WHERE id = ?', nil, booking_id)
    if session[:user_id]
      DBHandler.execute('UPDATE bookings SET user_id = ?, session_id = ? WHERE id = ?', session[:user_id], nil, booking_id)
      DBHandler.execute('UPDATE users SET points = pointds + ?', total_points)
    end
  end
end
