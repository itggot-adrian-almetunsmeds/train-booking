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
    @signed_in = if session[:user_id].is_a? Integer
                   @admin = User.admin?(session[:user_id])

                   true
                 else
                   @admin = false
                   false
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
        redirect '/'
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
    p "this ran"
    payload = request.body.read
    p payload
    params[:checkout] = payload
    '/checkout'
  end

  get '/checkout' do
    z = JSON.parse(params[:checkout])
    p z
    @tickets = []
    z.each do |temp|
      @tickets << temp
    end
  end
end
