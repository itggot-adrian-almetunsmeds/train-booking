# frozen_string_literal: true

require_relative 'db_handler'
require_relative 'tickets'
require_relative 'seats'

# Handles all bookings
class Booking < DBHandler
  set_table :booking
  has_a [:service,
         # {alias: 'dep', table: }
         'platforms AS dep ON service.departure_id = dep.id',
         'platforms AS arr ON service.arrival_id = arr.id',
         'destination as arrival ON arr.destination_id = arrival.id',
         'destinations as departure ON dep.destination_id = departure.id',
         booking_connector: :tickets]

  set_columns :id, :status, :session_id, :user_id, :'departure.name', :'arrival.name',
              :arrival_time, :departure_time, :points, :amount, :'tickets.id',
              :price, :service_id

  # attr_reader :user_id, :departure_location, :departure_platform, :arrival_location, :arrival_platform,
  #             :ticket_name, :total_price, :departure_time, :arrival_time, :total_points, :tickets,
  #             :booking_id, :status, :session_id, :id

  # attr_writer :total_price, :status, :session_id, :user_id
  # def initialize(id)
  #   if id.is_a? String
  #     data = DBHandler.execute(
  #       'SELECT bookings.id, bookings.status, bookings.session_id, bookings.id, user_id,' \
  #       ' departure.name AS departure_location, arrival.name AS arrival_location,'\
  #       ' dep.name AS departure_platform, arr.name AS arrival_platform, tickets.name AS ticket_name,'\
  #       ' arrival_time, departure_time, points, amount, tickets.id AS ticket_id,'\
  #       ' bookings.price as booking_price, bookings.service_id'\
  #       ' FROM bookings'\
  #       ' LEFT JOIN booking_connector'\
  #       ' ON bookings.id = booking_connector.booking_id'\
  #       ' LEFT JOIN tickets'\
  #       ' ON booking_connector.ticket_id = tickets.id'\
  #       ' LEFT JOIN services'\
  #       ' ON bookings.service_id = services.id'\
  #       ' LEFT JOIN platforms AS dep'\
  #       ' ON services.departure_id = dep.id'\
  #       ' LEFT JOIN platforms AS arr'\
  #       ' ON services.arrival_id = arr.id'\
  #       ' LEFT JOIN destinations as arrival'\
  #       ' ON arr.destination_id = arrival.id'\
  #       ' LEFT JOIN destinations as departure'\
  #       ' ON dep.destination_id = departure.id'\
  #       ' WHERE session_id = ?', id
  #     )
  #   else
  #     data = DBHandler.execute(
  #       'SELECT bookings.id, bookings.status, bookings.session_id, bookings.id, user_id,' \
  #       ' departure.name AS departure_location, arrival.name AS arrival_location,'\
  #       ' dep.name AS departure_platform, arr.name AS arrival_platform, tickets.name AS ticket_name,'\
  #       ' arrival_time, departure_time, points, amount, tickets.id AS ticket_id,'\
  #       ' bookings.price as booking_price, bookings.service_id'\
  #       ' FROM bookings'\
  #       ' LEFT JOIN booking_connector'\
  #       ' ON bookings.id = booking_connector.booking_id'\
  #       ' LEFT JOIN tickets'\
  #       ' ON booking_connector.ticket_id = tickets.id'\
  #       ' LEFT JOIN services'\
  #       ' ON bookings.service_id = services.id'\
  #       ' LEFT JOIN platforms AS dep'\
  #       ' ON services.departure_id = dep.id'\
  #       ' LEFT JOIN platforms AS arr'\
  #       ' ON services.arrival_id = arr.id'\
  #       ' LEFT JOIN destinations as arrival'\
  #       ' ON arr.destination_id = arrival.id'\
  #       ' LEFT JOIN destinations as departure'\
  #       ' ON dep.destination_id = departure.id'\
  #       ' WHERE bookings.id = ?', id
  #     )
  # end
  #   @tickets = []
  #   @total_points = 0
  #   data.each do |z|
  #     next if z['amount'] == 0

  #     ticket = Ticket.new(z['ticket_id'], z['amount'])
  #     seat = Seat.booked_seats_ticket z['id'], z['ticket_id']
  #     ticket = Objects.merge(seat, ticket)

  #     ticket.instance_variables.each { |k| self.class.send(:attr_reader, k.to_s[1..-1].to_sym) }
  #     tickets << ticket
  #     @total_points += ticket.total_points
  #   end
  #   data = data.first
  #   @total_price = data['booking_price']
  #   @id = data['id']
  #   @session_id = data['session_id']
  #   @status = data['status']
  #   @booking_id = data['id']
  #   @user_id = data['user_id']
  #   @departure_location = data['departure_location']
  #   @departure_platform = data['departure_platform']
  #   @arrival_location = data['arrival_location']
  #   @arrival_platform = data['arrival_platform']
  #   @departure_time = DateTime.strptime(data['departure_time'], '%s')
  #   @arrival_time = DateTime.strptime(data['arrival_time'], '%s')
  # end

  def confirm(booking, user_id = nil)
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
    booking.id
  end

  def self.create(payload, session, _back)
    payload = JSON.parse(payload)['value']
    payload = JSON.parse(payload)

    stored = []
    payload.each do |ticket|
      next if ticket['amount'].to_i.zero?

      temp = Ticket.fetch_where('ticket.id': ticket['id'], service_id: ticket['booking_id'])
      temp.instance_variable_set(:@amount, ticket['amount'])
      temp.singleton_class.send(:attr_accessor, :amount)
      stored << temp
    end

    p stored

    price_sum = 0
    stored.each do |ticket|
      price_sum += ticket.price * ticket.amount.to_i
    end

    booking = Booking.new(user_id: session['user_id'], price: price_sum,
                          service_id: stored.first.ticket_connector.service_id,
                          booking_time: DateTime.now.to_s,
                          status: 0,
                          session_id: session.id.public_id)
    booking.save
    stored.each do |ticket|
      p Seat.reserve(ticket.amount, ticket.ticket_connector.service_id,
                     booking.id, ticket.id)
    end
  end

  #   tickets = []
  #   query = ''
  #   payload.each do |ticket|
  #     unless ticket['amount'].to_i == 0
  #       tickets << ticket['id']
  #       query += " ticket.id = #{ticket['id']}"
  #     end
  #   end
  #   query = query[0..-4]
  #   service = back.split('/')
  #   DBHandler.sql_operator(table: :ticket,
  #                          where: { or: query },
  #                          select: 'price, id')
  #   # price = DBHandler.execute("SELECT price, id from tickets WHERE #{query}",
  #   # tickets[0..-1])

  #   # Prevents there from being multiple unconfirmed tickets from the same session preventing accidental
  #   # dubble booking
  #   DBHandler.execute('DELETE FROM bookings WHERE session_id = ?', session.id)
  #   if session[:user_id]
  #     DBHandler.execute('INSERT INTO bookings (price, user_id, service_id, booking_time, status, ' \
  #               'session_id) VALUES (?,?,?,?,?,?)', price_sum, session[:user_id], service[-1].to_i,
  #                       DateTime.now.to_s, 0, session.id)
  #   else
  #     DBHandler.execute('INSERT INTO bookings (price, service_id, booking_time, status, session_id) '\
  #     'VALUES (?,?,?,?,?)', price_sum, service[-1].to_i, DateTime.now.to_s, 0, session.id)
  #   end
  #   booking = DBHandler.last('bookings').first
  #   payload.each do |ticket|
  #     next if ticket['amount'].to_i == 0

  #     Seat.reserve(ticket['amount'].to_i, service[-1].to_i, booking['id'], ticket['id'])
  #     DBHandler.execute('INSERT INTO booking_connector (booking_id, ticket_id, amount) '\
  #             'VALUES (?,?, ?)', booking['id'], ticket['id'], ticket['amount'])
  #   end
  # end
end
