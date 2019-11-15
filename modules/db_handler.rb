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
    @db = SQLite3::Database.new 'db/data.db' if @db.nil?
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
      connect.execute(sql)
    elsif values.class == Array
      connect.execute(sql, values[0..-1])
    else
      connect.execute(sql, values)
    end
  end

  def self.with_condition(table, conditions, values)
    execute("SELECT * FROM #{table} #{conditions}", values)
  end

  # Retrives all data from a given table
  #
  # Returns database values as hash
  def self.all(table)
    execute("SELECT * FROM #{table}")
  end

  # Retrives data from database table from row with given id
  #
  # table - String (Name of table)
  # id = String/Integer (id of row in db)
  #
  # Returns database values as hash
  def self.with_id(table, id)
    execute("SELECT * FROM #{table} WHERE id = ?", id).first
  end

  # Retrives the last row from a given table
  #
  # table - String (Name of table)
  # amount - Integer (Optional, number of rows to retrive)
  #
  # Returns database values as hash
  def self.last(table, amount = 1)
    execute("SELECT * FROM #{table} ORDER BY ID DESC LIMIT ?", amount)
  end

  # Writes an object into a given table
  #
  # table - String (Name of table)
  # object - Object to be written to table
  #
  # Returns the id of the new record (most of the time)
  def self.write_to_db(table, object)
    z = object.instance_variables
    q = []
    k = []
    # Returns values and their table
    z.each_with_index do |_, i|
      q << object.instance_variable_get(z[i])
      k << z[i].to_s.gsub('@', '')
    end
    k = k.to_s.gsub('[', '')
    k = k.to_s.gsub(']', '')

    # Handles generation of SQLInjection protection
    x = '?'
    if z.length > 1
      (z.length - 1).times do
        x += ',?'
      end
    end

    execute("INSERT INTO #{table} (#{k}) VALUES (#{x})", q)
    last(table)
  end

  def save(table, object)
    z = object.instance_variables
    q = []
    k = []
    z.each_with_index do |_, i|
      q << object.instance_variable_get(z[i])
      k << z[i].to_s.gsub('@', '') unless z[i].to_s.gsub('@', '') == 'id'
    end
    u = ''
    k.each_with_index do |_, i|
      u += "#{k[i]} = ?,"
    end
    u = u.chomp(',')
    DBHandler.execute("UPDATE #{table} SET #{u} WHERE id = ?", q)
    # TODO: Can this be made to self.execute or similar?
  end
end
