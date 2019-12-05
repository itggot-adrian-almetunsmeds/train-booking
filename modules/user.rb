# frozen_string_literal: true

require_relative 'db_handler'
require 'bcrypt'

# Handles the user
class User < DBHandler
  attr_reader :id, :first_name, :last_name, :email, :points, :admin, :password
  attr_writer :first_name, :last_name, :email, :points

  # Creates a new user or opens a excisting one
  #
  # Options - Integer(id), String(email)
  # Options - Hash containing first_name, last_name
  # email, password
  #
  # Returns instance variables containg user data
  # rubocop:disable Metrics/MethodLength
  def initialize(options = {}) # rubocop:disable Metrics/AbcSize
    if options.is_a?(Integer) || options.is_a?(String)
      user = if options.is_a?(String) && options.to_f.to_s != options
               # TODO: Make sure a new user provides a valid email
               DBHandler.with_condition('users', 'WHERE email = ?', options).first
             else
               DBHandler.with_id 'users', options
             end
      @id = user['id']
      @first_name = user['first_name']
      @last_name = user['last_name']
      @email = user['email']
      @points = user['points']
      @admin = user['admin']
      @password = user['password']
    else
      @first_name = options['first_name']
      @last_name = options['last_name']
      @email = options['email']
      @points = 0
      @admin = 0
      @password = BCrypt::Password.create(options['password'])
      @id = (DBHandler.write_to_db 'users', self).first['id']
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Determines if there is a user with a specific email adress
  #
  # email - User email (String)
  #
  # Returns weather there is already a user with that email
  def self.excists?(email)
    if (with_condition 'users', 'WHERE email = ?', email).first
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
    temp = with_id 'users', id
    temp['admin'] == 1
  end
end
