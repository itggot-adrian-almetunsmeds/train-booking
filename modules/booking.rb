# frozen_string_literal: true

require_relative 'db_handler'
require_relative 'tickets'

# Handles all bookings
class Booking < DBHandler
  attr_reader :user_id, :departure_location, :departure_platform, :arrival_location, :arrival_platform,
              :ticket_name, :total_price, :departure_time, :arrival_time, :total_points, :tickets,
              :booking_id, :status, :session_id, :id

  attr_writer :total_price, :status, :session_id, :user_id

  # rubocop:disable Metrics/MethodLength
  def initialize(session_id) # rubocop:disable Metrics/AbcSize
    data = DBHandler.execute(
      'SELECT bookings.id, bookings.status, bookings.session_id, bookings.id, user_id,' \
      ' departure.name AS departure_location, arrival.name AS arrival_location,'\
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
    @total_points = 0
    data.each do |z|
      ticket = Ticket.new(z['ticket_id'], z['amount'])
      tickets << ticket
      @total_points += ticket.total_points
    end
    data = data.first
    @total_price = data['booking_price']
    @id = data['id']
    @session_id = data['session_id']
    @status = data['status']
    @booking_id = data['id']
    @user_id = data['user_id']
    @departure_location = data['departure_location']
    @departure_platform = data['departure_platform']
    @arrival_location = data['arrival_location']
    @arrival_platform = data['arrival_platform']
    @departure_time = DateTime.strptime(data['departure_time'], '%s')
    @arrival_time = DateTime.strptime(data['arrival_time'], '%s')
  end
  # rubocop:enable Metrics/MethodLength

  def confirm(booking, user_id = nil) # rubocop:disable Metrics/MethodLength
    booking.status = 1
    booking.session_id = nil
    if user_id
      booking.user_id = user_id
      user = User.new(user_id)
      user.points += total_points
      user.save 'users'
    end
    booking.save 'bookings', params: [{ key: 'status', value: booking.status },
                                      { key: 'session_id', value: booking.session_id },
                                      { key: 'user_id', value: booking.user_id }], id: booking.id
  end

  # rubocop:disable Metrics/MethodLength
  def self.create(payload, session, back) # rubocop:disable Metrics/AbcSize
    payload = JSON.parse(payload)['value']
    payload = JSON.parse(payload)
    tickets = []
    query = ''
    payload.each do |ticket|
      tickets << ticket['id']
      query += ' tickets.id = ? OR'
    end
    query = query[0..-4]
    service = back.split('/')
    price = DBHandler.execute("SELECT price, id from tickets WHERE #{query}",
                              tickets[0..-1])
    price_sum = 0
    payload.each do |ticket|
      price.each do |entity|
        if ticket['id'].to_i == entity['id'].to_i
          price_sum += entity['price'].to_i * ticket['amount'].to_i
        end
      end
    end

    # Prevents there from being multiple unconfirmed tickets from the same session preventing accidental
    # dubble booking
    DBHandler.execute('DELETE FROM bookings WHERE session_id = ?', session.id)
    if session[:user_id]
      DBHandler.execute('INSERT INTO bookings (price, user_id, service_id, booking_time, status, ' \
                'session_id) VALUES (?,?,?,?,?,?)', price_sum, session[:user_id], service[-1].to_i,
                        DateTime.now.to_s, 0, session.id)
    else
      DBHandler.execute('INSERT INTO bookings (price, service_id, booking_time, status, session_id) '\
      'VALUES (?,?,?,?,?)', price_sum, service[-1].to_i, DateTime.now.to_s, 0, session.id)
    end
    booking = DBHandler.last('bookings').first
    payload.each do |ticket|
      DBHandler.execute('INSERT INTO booking_connector (booking_id, ticket_id, amount) '\
              'VALUES (?,?, ?)', booking['id'], ticket['id'], ticket['amount'])
    end
  end
  # rubocop:enable Metrics/MethodLength
end
