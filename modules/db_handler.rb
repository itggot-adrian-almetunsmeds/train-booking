# frozen_string_literal: true

require 'sqlite3'

# Creates a new class dynamically.
class ClassFactory
  def self.create_class(new_class, parent, *fields)
    c = Class.new(parent) do
      fields.each do |field|
        define_method field.intern do
          instance_variable_get("@#{field}")
        end
        define_method "#{field}=".intern do |arg|
          instance_variable_set("@#{field}", arg)
        end
      end
    end

    Object.const_set new_class, c
  end
end

# A class handeling a databse object
class DBHandler # rubocop:disable Metrics/ClassLength
  attr_accessor :table, :tables

  # Initializes a new instance of an object and sets provided data
  def initialize(params)
    raise 'No data provided' unless params.is_a? Hash

    params.each do |key, value|
      instance_variable_set("@#{key}", value)
      singleton_class.send(:attr_accessor, key.to_s)
    end
  end

  # Writes an object to db
  #
  # Returns nothing
  def save
    if instance_variables.include? :@id # Update
      update self, self.class.to_s.downcase
      # TODO: Switch from self.class to @table.
      # FIXME:
      #
      # Did not work on when I tried but this should also work relatively good.
    else # Insert
      hash = {}
      instance_variables.map { |q| hash[q.to_s.gsub('@', '')] = instance_variable_get(q) }
      id = insert hash, self.class.to_s.downcase
      instance_variable_set(:@id, id)
      singleton_class.send(:attr_accessor, :id)
    end
  end

  # Updates a object using provided table
  #
  # object - Object to be updated
  # table - DB table to update (String)
  #
  # Returns nothing
  def update(object, table)
    variables = object.instance_variables
    values = []
    query = "UPDATE #{table} SET "
    variables.each_with_index do |var, index|
      next unless object.instance_variable_get(var).is_a?(String) ||
                  object.instance_variable_get(var).is_a?(Integer)

      query += if index.zero?
                 " #{var.to_s.gsub('@', '')} = ?"
               else
                 ", #{var.to_s.gsub('@', '')} = ?"
               end
      values << object.instance_variable_get(var)
    end
    query += ' WHERE id = ?'
    values << object.instance_variable_get(:@id)
    DBHandler.execute(query, values.flatten[0..-1])
  end

  #########################################################
  # PUBLIC METHODS
  # CONFIGURING / SET UP

  # Sets table
  def self.set_table(string)
    @table = string
  end

  class << self
    attr_reader :table
  end

  # Sets joins
  def self.has_a(tables)
    if @tables.nil?
      @tables = [tables]
    else
      @tables << tables
    end
    return unless class_exists?(tables.to_s.downcase.capitalize)

    if @columns.nil?
      @columns = [Object.const_get(tables.to_s.downcase.capitalize).columns]
    else
      @columns << Object.const_get(tables.to_s.downcase.capitalize).columns
    end
    @columns = @columns.flatten
    @tables[-1] = { "#{@tables.last.to_sym}": Object.const_get(tables.to_s.downcase.capitalize).tables }
  end

  class << self
    attr_reader :tables
  end

  # Sets columns
  def self.set_columns(*symbols)
    symbols = symbols.flatten.map { |x| x = "#{@table}.#{x}" unless x.to_s.include?('.'); x }
    if @columns.nil?
      @columns = symbols.flatten
    else
      @columns << symbols.flatten
      @columns = @columns.flatten
    end
  end

  class << self
    attr_reader :columns
  end

  # Connects to the database
  #
  # If a db already excists then return it
  #
  # Returns a database objekt
  def self.connect(path = nil)
    path = 'db/data.db' if path.nil?
    @db ||= SQLite3::Database.new(path)
    @db.results_as_hash = true
    @db
  end
  ######################
  # FETCHING/UPDATING/INSERTING/CREATING/DELETING

  # Fetches all entries given a table (Alternative)
  def self.all
    fetch_all
  end

  # Fetches all entries given a table
  def self.fetch_all
    sql_operator(
      table: @table,
      join: @tables,
      select: @columns
    )
  end

  # Fetches a entry based on the id
  # Returns the object
  def self.fetch_by_id(id, table = nil)
    table = @table if table.nil?
    raise 'Provided table is invalid' unless table.is_a?(String) || table.is_a?(Symbol)

    sql_operator table: @table, where: "#{table}.id = #{id}", join: @tables, select: @columns
  end

  # Fetches a entry based on the id (Alternative)
  # Returns the object
  def self.with_id(id, table = nil)
    fetch_by_id(id, table)
  end

  # Fetches the first rows
  #
  # num - Number or rows to fetch
  #
  # Returns objects containing the given sql response
  def self.fetch_first(num = nil)
    if num.nil?
      sql_operator(
        table: @table,
        join: @tables,
        limit: 1,
        select: @columns
      )
    else
      sql_operator(
        table: @table,
        join: @tables,
        limit: num,
        select: @columns
      )
    end
  end

  # Fetches the last rows
  #
  # num - Number or rows to fetch
  #
  # Returns objects containing the given sql response
  def self.fetch_last(num = nil)
    if num.nil?
      sql_operator(
        table: @table,
        join: @tables,
        limit: -1,
        select: @columns
      )
    else
      sql_operator(
        table: @table,
        join: @tables,
        limit: -num,
        select: @columns
      )
    end
  end

  # Fetches where conditions are met
  #
  # params - where params (Array - Hash, String)
  #
  # Returns objects containing the given sql response
  def self.fetch_where(params)
    if params.is_a? Hash
      holder = []
      params.each do |key, value|
        holder << "#{key} = #{value}"
      end
      sql_operator(
        table: @table,
        join: @tables,
        where: holder,
        select: @columns
      )
    else
      sql_operator(
        table: @table,
        join: @tables,
        where: params,
        select: @columns
      )
    end
  end

  # Fetche_where (Alternative)
  def self.fetch_by_condition(*conditions)
    fetch_where(conditions.first)
  end

  # Inserts data into the db
  #
  # data - Hash
  # table - String (Optional)
  #
  # Returns nothing
  def insert(data, table = nil)
    table = @table if table.nil?
    insert!(data, table)
  end

  # Decides if the provided argument has to be processed before execution
  # Public for use in special sql queries
  def self.sql_operator(*args)
    sql_operator!(args)
  end

  #########################################################
  # "PRIVATE" METHODS

  ######################
  # VALIDATORS

  # Validates table "query"
  #
  # arg - Data to validate
  #
  # Returns the table unless ther is an error
  def self.validate_table_input(arg)
    raise 'A hash is not a valid input format for table' if arg.is_a? Hash

    if arg.is_a? Array
      raise 'Only one table can be selected' if arg.flatten.length > 1

      arg.flatten[0].to_s
    else
      arg.to_s
    end
  end

  ######################
  # CONSTRUCTORS

  # Objectifies entered data. Either initializing a new object instance with the
  # given data or updates a excisting instance
  #
  # array - Array or Array containing a Hash containing data
  # class_holder - "Origin" instance
  #
  # Returns nothing
  def self.object_constructor(array, class_holder)
    p array
    if array.length == 1
      array = array.flatten
      object_holder = []
      array.first.each do |string, value|
        unless class_exists?(string.split('.')[0].capitalize)
          ClassFactory.create_class string.split('.')[0].capitalize, DBHandler
          # There was no class with the given name.
          # Creating a new class to store the additional data
        end
        clazz = Object.const_get(string.split('.')[0].capitalize)
        string = string.split('.').last
        string = string.gsub('@', '')

        set = false
        object_holder.each do |temp|
          # Checks if there is a class in the object holder that matches the gathered data
          next unless temp.class == clazz

          temp.instance_variable_set("@#{string}", value)
          temp.class.send(:attr_accessor, string.to_sym)
          set = true
        end
        next if set

        temp = clazz.new("#{string}": value)
        temp.class.send(:attr_accessor, string.to_sym)
        object_holder << temp
        # TODO: Check if removing .class above works. If so
        # go with that method
        # This is based on the singleton_class thought, that only said instance
        # needs the attr_reader and not the class itself.
      end
      object_holder.each do |object|
        next unless object.class == self

        object_holder.each do |clazz|
          unless object.class == clazz.class
            object.instance_variable_set("@#{clazz.class.to_s.downcase}", clazz)
            object.class.send(:attr_accessor, clazz.class.to_s.downcase.to_sym)
          end
        end
        return object
      end
    else
      content_holder = []
      array.each do |hash|
        object_holder = []
        hash.each do |string, value|
          set = false
          unless class_exists?(string.split('.')[0].capitalize)
            ClassFactory.create_class string.split('.')[0].capitalize, DBHandler
            # There was no class with the given name.
            # Creating a new class to store the additional data
          end
          clazz = Object.const_get(string.split('.')[0].capitalize)
          string = string.split('.')[1] if string.split('.').length > 1

          object_holder.each do |temp|
            # Checks if there is a class in the object holder that matches the gathered data
            next unless temp.class == clazz

            temp.instance_variable_set("@#{string}", value)
            temp.class.send(:attr_accessor, string.to_sym)
            set = true
          end

          # If there was no object with set class create a new instance of it
          next if set

          temp = clazz.new("#{string.to_sym}": value)
          object_holder << temp
        end
        object_holder.each do |temporary_holder|
          # Gets the current values if there are some
          temp = class_holder.instance_variable_get("@#{temporary_holder.class.to_s.downcase}")
          # If there was a value add the newly created ones
          unless temp.nil?
            class_holder.instance_variable_set("@#{temporary_holder.class.to_s.downcase}",
                                               [temp, temporary_holder].flatten)
          end
          # Else set the newly created ones
          if temp.nil?
            class_holder.instance_variable_set("@#{temporary_holder.class.to_s.downcase}",
                                               temporary_holder)
          end
          class_holder.class.send(:attr_accessor, temporary_holder.class.to_s.downcase.to_sym)
        end

        object_holder.each do |object|
          next unless object.class == class_holder

          object_holder.each do |clazz|
            unless object.class == clazz.class
              object.instance_variable_set("@#{clazz.class.to_s.downcase}", clazz)
              object.class.send(:attr_accessor, clazz.class.to_s.downcase.to_sym)
            end
          end
          content_holder << object
        end
      end
      content_holder.flatten
    end
  end

  # Constructs selects
  #
  # Returns selects as SQL - Query (Partial string)
  def self.select_constructor(value, table)
    selects = 'SELECT'
    raise 'No columns provided' if value.nil?

    if value.is_a?(Symbol) || value.is_a?(String)
      selects = "SELECT #{value} FROM #{table}"
    else
      value.each do |item|
        set = false
        item.split(' ').each { |z| set = true if z.downcase == 'as' }
        if set
          selects += " #{item},"
        else
          item = item.to_s.gsub(/\s+/, '_')
          selects += " #{item} AS '#{item}',"
        end
      end
      selects = selects[0..-2] + " FROM #{table}"
    end
    selects
  end

  # Constructs wheres
  #
  # Reutrns a Array containing wheres as SQL - Query (Partial String), and associated values
  def self.where_constructor(value, table)
    if value.is_a? Array
      value = value.flatten
      value = value.first if value.length == 1
    end

    where = ' WHERE '
    values = []
    if value.is_a? String
      wheres = value.split(' ')
      wheres[0] = "#{table}.id" if wheres.first.downcase == 'id'
      where += "#{wheres.first} #{wheres[1].upcase} ?"
      values << wheres.last
    elsif value.is_a? Hash
      keys = value.keys
      keys.each_with_index do |key, index|
        p value[key]
        if value[key].is_a?(String) || value[key].is_a?(Integer) ||
           value[key].is_a?(Symbol) || !!value[key] == value[key] # Boolean?
          temp = value[key]
          temp = temp.to_s if temp.is_a? Symbol
          key = "#{table}.id" if key.downcase == 'id'
          where += if index.zero?
                     " #{key} = ?"
                   else
                     " AND #{key} = ?"
                   end
          values << temp
        elsif value[key].is_a? Array
          temp = value[key]
          where += " #{key} IN ("
          temp.each_with_index do |sav, i|
            where += if i.zero?
                       '?'
                     else
                       ',?'
                     end
            values << sav
          end
          where += ')'
        end
      end
    elsif value.is_a? Array
      value.each_with_index do |value, i|
        wheres = value.split(' ')
        wheres[0] = "#{table}.id" if wheres.first.downcase == 'id'
        where += if i.zero?
                   "#{wheres.first} #{wheres[1].upcase} ?"
                 else
                   " AND #{wheres.first} #{wheres[1].upcase} ?"
                 end
        values << wheres.last
      end
    end
    [where, values]
  end

  # Consstructs joins
  #
  # Returns joins as SQL - query (Partial String)
  def self.join_constructor(joins, table, type = 'LEFT')
    sql_join = ''
    if joins.is_a? String
      sql_join = " #{type} JOIN #{joins}" if joins.downcase.include?('on')
    elsif joins.is_a? Array
      joins.each_with_index do |join, index|
        if join.is_a?(Array)
          sql_join += if joins.is_a? Hash
                        join_constructor(join, joins.keys[index])
                      else
                        join_constructor(join, table)
                      end
        elsif join.is_a? String
          sql_join += join_constructor(join, nil)
        elsif join.is_a? Hash
          if join.keys.length > 1
            join.keys.each do |key|
              if key.to_s.downcase.include?('connector')
                sql_join += " #{type} JOIN #{key} ON #{table}.id = #{key}.#{table}_id"
                sql_join += join_constructor(join[key], key)
                # THIS MIGHT NEED THE LAST JOIN STATEMENT FROM BELOW
              else
                sql_join += " #{type} JOIN #{key} ON #{table}.#{key}_id = #{key}.id"
                sql_join += join_constructor(join[key], key)
                if join[key].is_a? Symbol
                  sql_join += " #{type} JOIN #{join[key]} ON #{key}.#{join[key]}_id = #{join[key]}.id"
                end
              end
            end
          else
            sql_join += if join.keys[0].to_s.downcase.include?('connector')
                          " #{type} JOIN #{join.keys[0]} ON #{table}.id = #{join.keys[0]}.#{table}_id"
                        else
                          " #{type} JOIN #{join.keys[0]} ON #{table}.#{join.keys[0]}_id " \
                            "= #{join.keys[0]}.id"
                        end
            sql_join += join_constructor(join[join.keys[0]], join.keys[0])
          end
        else # A symbol perhaps?
          sql_join += if join.to_s.downcase.include?('connector')
                        " #{type} JOIN #{join} ON #{table}.id = #{join}.#{table}_id"
                      else
                        " #{type} JOIN #{join} ON #{table}.#{join}_id = #{join}.id"
                      end
        end
      end
    elsif joins.is_a? Symbol
      sql_join += if joins.to_s.downcase.include?('connector')
                    " #{type} JOIN #{joins} ON #{table}.id = #{joins}.#{table}_id"
                  else
                    " #{type} JOIN #{joins} ON #{table}.#{joins}_id = #{joins}.id"
                  end
    end
    sql_join
  end

  # Constructs order
  #
  # Returns order as SQL - Query (Partial String)
  def self.order_constructor(value)
    raise 'Option Limit is not a hash.' unless value.is_a? Hash

    if value.keys.include?(:table) && value.keys.include?(:order)
      "ORDER BY #{value[:table]} #{value[:order]}"
    elsif !value[:table].nil?
      "ORDER BY #{value[:table]}"
    elsif !value[:order].nil?
      "ORDER BY id #{value[:order]}"
    else
      raise 'Invalid limit parsing. Missing order or table paramateter.'
    end
  end

  ######################
  # GENERAL "PRIVATE" METHODS

  def self.class_exists?(class_name)
    klass = Module.const_get(class_name)
    klass.is_a?(Class)
  rescue NameError
    false
  end

  # Acts as manager for construction of SQL queries
  #
  # Returns a list of lists containing objects representing databases entries
  def self.sql_operator!(args)
    args = args.first
    raise 'No table provided' unless args.keys.include? :table

    join = ''
    where = ''
    order = ''
    limit = ''
    selects = 'SELECT'
    values = []
    args[:table] = validate_table_input args[:table]
    args.each do |key, value|
      case key
      when :select
        selects = select_constructor(value, args[:table])
      when :join
        join = join_constructor(value, args[:table])
      when :where
        temp = where_constructor(value, args[:table])
        where = temp[0]
        values << temp[1]
      when :limit
        limit = if value.to_i.negative?
                  order = 'ORDER BY id DESC' if args[:order].nil?
                  " LIMIT #{value * -1}"
                else
                  " LIMIT #{value}"
                end
      when :order
        order = order_constructor(value)
      end
    end
    selects = "SELECT * FROM #{args[:table]}" if selects == 'SELECT'
    sqlquery = "#{selects} #{join} #{where} #{order} #{limit}"
    object_constructor execute(sqlquery, values.flatten[0..-1]), self
  end

  # Insert method
  #
  # Reuturns id
  private def insert!(data, table)
    if !data.is_a? Hash
      write_to_db(data, table)
    else
      raise 'Data input needs to be a hash.' unless data.is_a? Hash

      query = "INSERT INTO #{table} ( "
      values = 'VALUES ('
      stored = []
      data.each do |key, value|
        query += "#{key},"
        values += '?,'
        stored << value
      end
      query[-1] = ') '
      values[-1] = ') '
      execute(query + values, stored)
    end
  end

  # Writes an object into a given table
  #
  # table - String (Name of table)
  # object - Object to be written to table
  #
  # Returns nothing
  private def write_to_db(object, table)
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
  end

  # Executes given sql code like SQLite3 gem
  #
  # sql - String (SQL code)
  # values - Array containing a list of values (optional)
  #
  # Returns sqlresult as hash
  def self.execute(sql, *values)
    p '__________________________'
    p sql
    p values
    @db ||= DBHandler.connect
    if values == []
      @db.execute(sql)
    elsif values[0].is_a? Array
      @db.execute(sql, values[0][0..-1])
    else
      @db.execute(sql, values[0..-1])
    end
  end

  # Returns id
  def execute(sql, *values)
    p '__________________________'
    p sql
    p values
    # Inserts
    @db ||= DBHandler.connect
    @db.transaction
    if values == []
      @db.execute(sql)
    elsif values[0].is_a? Array
      @db.execute(sql, values[0][0..-1])
    else
      @db.execute(sql, values[0..-1])
    end
    if sql.include?('INSERT')
      table = sql.split(' ')[2]
      object = DBHandler.sql_operator(
        table: table,
        limit: -1,
        select: :id
      ).first
      id = object.first.id if object.is_a? Array
      id = object.id unless object.is_a? Array
    end
    @db.commit
    id
  end
end

# require_relative 'data_holder' # Needs to be placed at the bottom due to load priority
