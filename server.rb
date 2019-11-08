# frozen_string_literal: true

require_relative 'modules/trains'
require_relative 'modules/train_models'
require_relative 'modules/services'

class Server < Sinatra::Base
  enable :sessions
  # Redirects a user visiting a admin page if they are not logged in and have admin rights
  # before '/admin' do
  #   redirect '/' if session[:user_id].nil? # || # TODO: or has admin rights
  # end

  get '/admin' do
    @trains = Trains.all
    @train_models = TrainModels.all
    @services = Services.all
    slim :'admin/index'
  end
end
