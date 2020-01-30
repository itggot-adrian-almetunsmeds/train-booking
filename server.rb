# frozen_string_literal: true

require_relative 'modules/user'
require_relative 'modules/services'
require_relative 'modules/booking'

# Handeles server routes
class Server < Sinatra::Base # rubocop:disable Metrics/ClassLength
  enable :sessions

  before do
    if session[:user_id].is_a? Integer
      @admin = User.admin?(session[:user_id])
      @user = User.fetch_where id: session[:user_id]
      @signed_in = true
    else
      @admin = false
      @signed_in = false
    end
  end

  # Redirects a user visiting a admin page if they are not logged in and have admin rights
  before '/admin*' do
    redirect '/' if !@signed_in || !@admin
    @error = session[:error] if session[:error]
  end

  # Displays the admin configuration page
  get '/admin' do
    @bookings = [Booking.all]
    @services = [Service.all]
    @users = [User.all]
    slim :'admin/index'
  end

  # Displays the edit form for the user
  get '/user/:id/edit' do
    redirect '/' unless session[:user_id]
    if @user.id == params['id'].to_i
      @users = [@user]
      slim :'templates/user_list'
    end
    redirect back
  end

  # Removes the user from the db
  get '/user/:id/delete' do
    if @user.id == params['id'].to_i || @admin
      User.fetch_where(id: params['id'].to_i).delete
      redirect back
    end
    session[:error_user] = 'Unauthorized'
    redirect '/'
  end

  # Post. Updates the user data
  post '/user/:id/update' do
    if @user.id == params['id'].to_i || @admin
      begin
        if params['password'] && params['password'] != ''
          params['password'] = User.new(params).save
        else
          u = User.fetch_where id: params['id'].to_i
          u.first_name = params['first_name']
          u.last_name = params['last_name']
          u.email = params['email']
          u.points = params['points']
          u.save
        end
      rescue StandardError
        session[:error] = 'Invalid data provided'
      end
    end
    redirect "/user/#{params['id']}"
  end

  # Displays a user given the id but only if having the rights to do so.
  get '/user/:id' do
    if session[:user_id].to_i == params[:id].to_i || @admin
      @user = User.fetch_where id: params[:id]
      @bookings = Booking.fetch_where user_id: params[:id]
      slim :'user/overview'
    else
      redirect '/'
    end
  end

  # TODO: Remove booking when canceled by leaving page before
  # the booking is completed.
  #
  # Currently the seats are still reserved to the "ongoing"
  # session
  # Use a delay to timeout a booking or use continious request
  # to the server to indicate that the booking is still alive.

  # Removes a booking if the user has the rights to do so.
  get '/booking/:id/delete' do
    @bookings = Booking.fetch_where id: params[:id]
    redirect Booking.cancel(params[:id], session, params, back, @admin)
  end

  # Home page
  get '/' do
    @error = session[:error_user]
    session[:error_user] = nil

    @search = session[:search]
    session[:search] = nil
    slim :index
  end

  # Register form
  get '/register' do
    @error = session[:error_user] if session[:error_user]
    slim :'user/register'
  end

  # Presents search results
  get '/search' do
    redirect '/' if session[:search].nil?

    x = JSON.parse(session[:search])
    session[:search] = nil
    if session.is_a? Array
      session[:search_dep] = x.first['departure_id']
      session[:search_arr] = x.first['departure_id']
    else
      session[:search_dep] = x['departure_id']
      session[:search_arr] = x['arrival_id']
    end
    @service = Service.search(x)
    if @service.is_a? String
      @error = @service
      @service = false
    end
    @back_url = back
    slim :search
  end

  # Presents a specific service and makes it possible to
  # selct/add tickets to a booking
  get '/service/:id' do
    @service = Service.with_id(params['id'])
    @service.departure_time = DateTime.strptime(@service.departure_time, '%s')
    @service.arrival_time = DateTime.strptime(@service.arrival_time, '%s')
    @tickets = @service.tickets
    slim :booking
  end

  # Post. Updates service data
  post '/service/:id/update' do
    if @admin
      begin
        params['departure_time'] = DateTime.parse("#{params['departure_time']}:00+01:00").to_time.to_i
        params['arrival_time'] = DateTime.parse("#{params['arrival_time']}:00+01:00").to_time.to_i
        Service.new(params).save
      rescue StandardError
        session[:error] = 'Invalid data provided'
      end
      redirect back
    else
      redirect '/'
    end
  end

  # Post. Creates a new service or raises an error
  post '/service/create' do
    if @admin && params != []
      begin
        ticket_id = params['ticket_id']
        params.delete('ticket_id')
        params['departure_time'] = DateTime.parse(params['departure_time']).to_time.to_i
        params['arrival_time'] = DateTime.parse(params['arrival_time']).to_time.to_i
        params['empty_seats'] = Train.fetch_where(id: params['train_id'].to_i).train_type.capacity
        temp = Service.new(params)
        temp.save(true)
        ticket_id.flatten.each do |z|
          Ticket_connector.new(service_id: temp.id, ticket_id: z).save unless z.to_i.negative?
        end
      rescue StandardError
        session[:error] = 'Invalid data provided'
      end
      redirect back
    else
      redirect '/'
    end
  end

  ##########################################################################
  # Post. Login form
  # Signs the user in if the correct credentials are provided.
  post '/login' do
    if User.excists? params['email']
      user = User.fetch_where email: params['email']
      if BCrypt::Password.new(user.password) == params[:password]
        session[:user_id] = user.id
      else
        session[:error_user] = 'There is no user with that password.'
      end
    else
      session[:error_user] = 'There is no such user.'
    end
    redirect back
  end

  # Post. Register form
  # Creates a new user if there is no registered user with the same
  # email. Then signs the new user in.
  post '/register' do
    if User.excists? params['email']
      session[:error_user] = 'User already excists'
      redirect back
    else
      user = User.new(params)
      user.save
      session[:user_id] = user.id
      redirect '/'
    end
  end

  # Post. Logout
  # Signs the user out of the session and clears the session
  post '/logout' do
    session[:user_id] = nil
    session.clear
    redirect back
  end

  # Post. Search form from /index
  # Initializes the search process and redirects the user to the
  # search results
  post '/search' do
    session[:search] = { dep: params['departure'], arr: params['arrival'], time: params['date'] }.to_json
    redirect '/search'
  end

  # Post. Tickets
  # initialzes the booking process.
  # Reserves seats, adds the order to the db
  # Redirects to the checkout page if the booking is valid
  post '/ticket' do
    payload = request.body.read
    begin
      Booking.create(payload, session, back)
      '/checkout'
    rescue StandardError => e
      print e.backtrace
      session[:error_user] = 'Unable to complete booking'
      '/'
    end
  end

  # Checkout page
  # Let's the user confirm the booking
  get '/checkout' do
    @booking = Booking.fetch_where(session_id: session.id.public_id)
    redirect '/' if @booking == []
    @total_points = 0
    if @booking.is_a? Array
      @booking.each do |booking|
        @total_points += booking.booking_connector.amount.to_i * booking.ticket.points.to_i
      end
    else
      @total_points = @booking.booking_connector.amount.to_i * @booking.ticket.points.to_i
    end
    session[:points] = @total_points

    slim :checkout
  end

  # Post. Confirms the booking and completes it
  # Redirects to the ticket overview if booking is valid
  post '/confirmticket' do
    begin
      booking = Booking.fetch_where(session_id: session.id.public_id)
      id = if booking.is_a? Array
             booking.each do |book|
               book.confirm(session[:points], session[:user_id])
             end
             booking.flatten.first.id
           else
             booking.confirm(session[:points], session[:user_id])
             booking.id
           end

      session[:booking_id] = id
      redirect 'booking-complete'
    rescue StandardError
      session[:error_user] = 'Unable to complete booking'
      redirect '/'
    end
  end

  # Shows the assigned tickets, with seats and dep/arr times/platforms
  # Redirects to '/' if not in booking process
  get '/booking-complete' do
    redirect '/' unless session[:booking_id]
    @booking = Booking.fetch_where id: session[:booking_id]
    @seats = Seat_connector.fetch_where(booking_id: session[:booking_id])
    slim :bookings
  end
  not_found do
    session[:error_user] = 'Page not found'
    redirect '/'
  end
end
