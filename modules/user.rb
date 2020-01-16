# frozen_string_literal: true

require_relative 'db_handler'
require 'bcrypt'

# Handles the user
class User < DBHandler
  set_table :user
  set_columns :first_name, :last_name, :id, :password, :points, :admin, :email

  def initialize(params)
    params['password'] = BCrypt::Password.create(params['password'])
    super(params)
  end

  # Determines if there is a user with a specific email adress
  #
  # email - User email (String)
  #
  # Returns weather there is already a user with that email
  def self.excists?(email)
    if (fetch_where email: email).is_a? User
      true
    else
      false
    end
  end

  # Determines if the user has admin rights
  #
  # id - User id (Integer)
  #
  # Returns true or false
  def self.admin?(id)
    temp = fetch_by_id id
    temp.admin == 1
  end
end
