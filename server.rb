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

  get '/admin' do
    @trains = Trains.all
    @train_models = TrainModels.all
    @services = Services.all
    slim :'admin/index'
  end

  get '/' do
    @admin = false
    @error = session[:error_user]
    slim :index
  end

  get '/register' do
    @error = session[:error_user] if session[:error_user]
    slim :'user/register'
  end

  get '/search' do
    x = JSON.parse(session[:search])
    session[:search] = nil
    slim :search
  end
  ##########################################################################
  post '/login' do
    if User.excists? params['email']
      user = User.new(params['email'])
      if params[:password] == BCrypt::Password.new(user.password)
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
    session[:search] = [params['departure'], params['arrival']].to_json
    redirect '/search'
  end
end
