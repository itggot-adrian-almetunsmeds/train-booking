# frozen_string_literal: true

require_relative 'modules/trains'
require_relative 'modules/user'
# require_relative 'modules/train_models'
# require_relative 'modules/services'

# Handeles server routes
class Server < Sinatra::Base
  enable :sessions
  # Redirects a user visiting a admin page if they are not logged in and have admin rights
  before '/admin' do
    redirect '/' if session[:user_id].nil? || !User.admin?(session[:user_id])
  end

  before do
    if session[:user_id].is_a? Integer
      @admin = User.admin?(session[:user_id])
      @signed_in = true
    else
      @admin = false
      @signed_in = false
    end
  end

  get '/admin' do
    @trains = Trains.all
    @train_models = TrainModels.all
    @services = Services.all
    slim :'admin/index'
  end

  get '/' do
    @error = session[:error_user]
    session[:error_user] = nil

    @search = session[:search]
    session[:search] = nil
    slim :index
  end

  get '/register' do
    @error = session[:error_user] if session[:error_user]
    slim :'user/register'
  end

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

  get '/service/:id' do
    @service = Service.with_id(params['id'])
    @dep = DBHandler.execute('SELECT * FROM destinations WHERE id = ?', @service['departure_id'])
    @arr = DBHandler.execute('SELECT * FROM destinations WHERE id = ?', @service['arrival_id'])
    @service['departure_time'] = DateTime.strptime(@service['departure_time'], '%s')
    @service['arrival_time'] = DateTime.strptime(@service['arrival_time'], '%s')
    @tickets = Service.tickets(params['id'])
    # # p @tickets
    # @tickets.each do |s|
    #   # p s
    # end
    slim :booking
  end
  ##########################################################################
  post '/login' do
    if User.excists? params['email']
      user = User.new(params['email'])
      if BCrypt::Password.new(user.password) == params[:password]
        session[:user_id] = user.id
        redirect back
      else
        session[:error_user] = 'There is no user with that password.'
        redirect back
      end
    else
      session[:error_user] = 'There is no such user.'
      redirect back
    end
  end

  post '/register' do
    if User.excists? params['email']
      session[:error_user] = 'User already excists'
      redirect back
    else
      user = User.new(params)
      session[:user_id] = user.id
      redirect '/'
    end
  end

  post '/logout' do
    session[:user_id] = nil
    redirect back
  end

  post '/search' do
    session[:search] = { dep: params['departure'], arr: params['arrival'], time: params['date'] }.to_json
    redirect '/search'
  end

  post '/ticket' do
    payload = request.body.read
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
    # TODO: Price retrival does not return the correct value
    price = DBHandler.execute("SELECT SUM(price) from tickets WHERE #{query}", tickets[0..-1]).first['SUM(price)']
    DBHandler.execute('DELETE FROM bookings WHERE session_id = ?', session.id)
    if session[:user_id]
      DBHandler.execute('INSERT INTO bookings (price, user_id, service_id, booking_time, status, session_id) VALUES (?,?,?,?,?,?)',
                        price, session[:user_id], service[-1].to_i, DateTime.now.to_s, 0, session.id)
    else
      DBHandler.execute('INSERT INTO bookings (price, service_id, booking_time, status, session_id) VALUES (?,?,?,?,?)',
                        price, service[-1].to_i, DateTime.now.to_s, 0, session.id)
    end
    booking = DBHandler.last('bookings').first
    payload.each do |ticket|
      DBHandler.execute('INSERT INTO booking_connector (booking_id, ticket_id, amount) VALUES (?,?, ?)', booking['id'], ticket['id'], ticket['amount'])
    end
    '/checkout'
  end

  get '/checkout' do
    @booking = Booking.new(session.id)

    # TODO: When booking has been completed remove the session_id from the db to prevent removing complete bookings
    # Also add rewardpoints when it has been completed

    slim :checkout
  end

  post '/confirmticket' do
    booking = Booking.new(session.id)
    # begin
    booking.confirm
    redirect 'booking'
    # rescue
    # session[:error_user] = "Unable to complete booking"
    # redirect '/'
    # end
  end
end
