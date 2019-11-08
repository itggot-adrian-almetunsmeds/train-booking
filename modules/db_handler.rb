# frozen_string_literal: true

require 'sqlite3'

# A class handeling sql
class DBHandler
  # Connects to the database
  #
  # If a db already excists then return it
  #
  # Returns a database objekt
  def self.connect
    if @db.nil?
      @db = SQLite3::Database.new 'db/data.db'
    else
      @db
    end
    @db.results_as_hash = true
    @db
  end

  # Executes given sql code like SQLite3 gem
  #
  # sql - String (SQL code)
  # values - Array containing a list of values (optional)
  #
  # Returns sqlresult as hash
  def self.execute(sql, values = nil)
    if values.nil?
      connect.execute(sql).first
    else
      connect.execute(sql, values[0..-1]).first
    end
  end
end
