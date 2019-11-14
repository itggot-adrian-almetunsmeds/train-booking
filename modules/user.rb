# frozen_string_literal: true

require_relative 'db_handler'
require 'bcrypt'

class User < DBHandler
  attr_reader :id, :first_name, :last_name, :email, :points, :admin, :password
  attr_writer :first_name, :last_name, :email, :points

  # Creates a new user or opens a excisting one
  # options - Integer(id), String(email)
  # Returns instance variables containg user data
  def initialize(options = {})
    if options.is_a?(Integer) || options.is_a?(String)
      user = if options.is_a? String
               DBHandler.with_condition 'users', 'WHERE email = ?', options
             else
               DBHandler.with_id 'users', options
             end
      @id = user[:id]
      @first_name = user[:first_name]
      @last_name = user[:last_name]
      @email = user[:email]
      @points = user[:points]
      @admin = user[:admin]
      @password = user[:passowrd]
    else
      @first_name = options['first_name']
      @last_name = options['last_name']
      @email = options['email']
      @points = 0
      @admin = 0
      @password = BCrypt::Password.create(options[:password])
      @id = write_to_db 'users', self
    end
  end

  def self.excists?(email)
    if with_condition 'users', 'WHERE email = ?', email
      true
    else
      false
    end
  end

  def self.admin?(id)
    temp = with_id 'users', id
    temp['admin'] == 1
  end
end
