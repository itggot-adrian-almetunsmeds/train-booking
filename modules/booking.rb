# frozen_string_literal: true

require_relative 'db_handler'
require_relative 'tickets'
require_relative 'seats'

# Handles all bookings
class Booking < DBHandler
  set_table :booking
  set_columns :id, :user_id, :price, :service_id, :booking_time, :status, :session_id
  has_a [:service, booking_connector: :ticket]

  # Cancels booking
  #
  # id - Booking id (Integer)
  # session - session Object
  # params - params Object
  # back - back object from rack (Object)
  # admin - Is user admin? (Boolean)
  #
  # Returns redirect url
  def self.cancel(_id, session, params, back, admin)
    @bookings = Booking.fetch_where id: params[:id]
    return '/' if @bookings == []

    temp = if @bookings.is_a? Array
             @bookings.first
           else
             @bookings
           end

    if session[:user_id] == temp.user_id || admin
      @seats = Seat_connector.fetch_where booking_id: params[:id]

      # Resets all associated seats
      if @seats.is_a? Array
        @seats.each do |seat|
          x = Seat.fetch_where(id: seat.seat_id)
          if x.is_a? Array
            x.each do |z|
              z.occupied = 0
              z.booking_id = 0
              z.save
            end
          else
            x.occupied = 0
            x.booking_id = 0
            x.save
          end
        end
      else
        x = Seat.fetch_where(id: @seats.seat_id)
        if x.is_a? Array
          x.each do |z|
            z.occupied = 0
            z.booking_id = 0
            z.save
          end
        else
          x.occupied = 0
          x.booking_id = 0
          x.save
        end
      end
      bookings = [BookingConnector.fetch_where(booking_id: params[:id])]
      points = 0
      bookings.flatten.each do |bok|
        ticket = Ticket.fetch_by_id(bok.ticket_id)
        points += bok.amount.to_i * ticket.price.to_i
      end

      u = User.fetch_where id: session[:user_id]

      u.points -= points

      Seat_connector.delete_where booking_id: params[:id]

      # Removes the booking
      Booking.delete_where id: params[:id]

      # Remove the rest of the booking connections
      BookingConnector.delete_where booking_id: params[:id]

      Service.update_empty_seats(temp.service_id)

      # Redirect back to the user dashboard when complete
      return back

    else
      p 'NON AUTHORIZED ACCESES'
      # Unathorized
      return '/'
    end
  end

  # Confirms the booking
  #
  # total_points - Total number of points for booking (Integer)
  # user_id - User id (Integer) Optional
  #
  # Returns nothing
  def confirm(total_points, user_id = nil)
    self.status = 1
    self.session_id = nil
    unless user_id.nil?
      user = User.fetch_where id: user_id
      user.points = user.points.to_i + total_points.to_i
      self.user_id = user_id

      user.save
    end
    save
  end

  # Creates a new booking
  #
  # payload - Booking information (Hash)
  # session - Session Obejct
  # back - Back path
  #
  # Returns nothing
  def self.create(payload, session, _back)
    Booking.delete_where session_id: session.id.public_id

    payload = JSON.parse(payload)['value']
    payload = JSON.parse(payload)

    stored = []
    total_seats = 0
    payload.each do |ticket|
      next if ticket['amount'].to_i <= 0

      total_seats += ticket['amount'].to_i

      temp = Ticket.fetch_where('ticket.id': ticket['id'], service_id: ticket['booking_id'])
      temp.instance_variable_set(:@amount, ticket['amount'])
      temp.singleton_class.send(:attr_accessor, :amount)
      stored << temp
    end

    seats = Seat.fetch_where(service_id: stored.first.service_id, occupied: 0)
    seats = if seats == []
              0
            elsif seats.is_a? Array
              seats.length
            else
              1
            end
    raise 'No available seats' if total_seats > seats

    price_sum = 0
    stored.each do |ticket|
      price_sum += ticket.ticket.price * ticket.amount.to_i
    end

    booking = Booking.new(user_id: session['user_id'], price: price_sum,
                          service_id: stored.first.service_id,
                          booking_time: DateTime.now.to_s,
                          status: 0,
                          session_id: session.id.public_id)
    booking.save
    stored.each do |ticket|
      x = BookingConnector.new(booking_id: booking.id, ticket_id: ticket.ticket.id,
                               amount: ticket.amount)
      x.save
      Seat.reserve(ticket.amount, ticket.service_id,
                   booking.id, ticket.ticket.id)
    end
  end
end

# Booking_Connector class for handeling the db table
class BookingConnector < DBHandler
  set_table :booking_connector
  set_columns :booking_id, :ticket_id, :amount
end
