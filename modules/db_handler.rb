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
  def self.execute(sql, *values)
    if values == []
      connect.execute(sql)
    elsif values[0].class == Array
      connect.execute(sql, values[0][0..-1])
    else
      connect.execute(sql, values[0..-1])
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
  # rubocop:disable Metrics/MethodLength
  def self.write_to_db(table, object) # rubocop:disable Metrics/AbcSize
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
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def save(table = nil, options = nil) # rubocop:disable Metrics/CyclomaticComplexity
    p options
    object = if options.nil? || options['object'].nil?
               self
             else
               options['object']
             end
    q = []
    k = []
    if options.nil? || options[:params].nil?
      z = object.instance_variables
      z.each_with_index do |_, i|
        q << object.instance_variable_get(z[i]) unless z[i].to_s.gsub('@', '') == 'id'
        k << z[i].to_s.gsub('@', '') unless z[i].to_s.gsub('@', '') == 'id'
      end
      q << object.id
    else
      options[:params].each do |param|
        q << param[:value]
        k << param[:key]
      end
    end
    u = ''
    k.each_with_index do |_, i|
      u += "#{k[i]} = ?,"
    end
    q << options[:id] if !options.nil? && !options[:params].nil?

    u = u.chomp(',')
    DBHandler.execute("UPDATE #{table} SET #{u} WHERE id = ?", q)
    # TODO: Can this be made to self.save or similar?
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
