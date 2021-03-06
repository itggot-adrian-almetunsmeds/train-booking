# frozen_string_literal: true

require 'sqlite3'

# Handles the ClassFactory
class ClassFactory
  # Creates a new class dynamically.
  #
  # new_class - New class name (String)
  # parent - Eventual parent to inherit from (String)
  # fields - Optional, Hash of fields and values
  #
  # Returns nothing
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

  #########################################################
  # PUBLIC METHODS
  # CONFIGURING / SET UP

  # Sets table
  #
  # string - (Symbol, String) of table
  #
  # Returns nothing
  def self.set_table(string) # rubocop:disable Namin/AccessorMethodName
    @table = string
  end

  # Getter
  class << self
    attr_reader :table
  end

  # Sets joins
  #
  # tables - (Hash, Sumbol, Array) Sets @tables based on input data
  #
  # Reuturns nothing
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

  # Sets joins with aliases
  #
  # table - Database table (String, Symbol)
  # alia - alias to join as
  # where_conditions - Conditions to apply for join
  #
  # Returns nothing
  def self.has_many(table, alia, where_conditions)
    if @has_many
      @has_many << table
    else
      @has_many = [table]
    end
    query = "#{table} AS #{alia} ON #{where_conditions}"
    if class_exists?(table.to_s.downcase.capitalize)

      # Get columns of joined table
      columns = [Object.const_get(table.to_s.downcase.capitalize).columns]
      # rubocop:disable Lint/UselessAssignment
      columns = columns.flatten.map { |column| column = "#{alia}.#{column.split('.').last}" }
      # rubocop:enable Lint/UselessAssignment

      if @columns.nil?
        @columns = [columns]
      else
        @columns << columns
      end
    end
    has_a query
  end

  # Getter
  class << self
    attr_reader :tables
  end

  # Sets columns
  #
  # symbols - (Symbol, Hash, Array, String) of columns
  #
  # Returns nothing
  def self.set_columns(*symbols) # rubocop:disable Naming/AccessorMethodName
    # rubocop:disable Style/Semicolon
    symbols = symbols.flatten.map { |x| x = "#{@table}.#{x}" unless x.to_s.include?('.'); x }
    # rubocop:enable Style/Semicolon
    if @columns.nil?
      @columns = symbols.flatten
    else
      @columns << symbols.flatten
      @columns = @columns.flatten
    end
  end

  # Getter
  class << self
    attr_reader :columns
  end

  # Connects to the database
  #
  # path - (String) Optional path to db
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

  # Writes an object to db
  #
  # Returns nothing
  def save
    if instance_variables.include? :@id # Update
      update self, self.class.to_s.downcase
    else # Insert
      hash = {}
      instance_variables.map { |q| hash[q.to_s.gsub('@', '')] = instance_variable_get(q) }
      id = insert hash, self.class.to_s.downcase
      unless id.nil?
        instance_variable_set(:@id, id)
        singleton_class.send(:attr_accessor, :id)
      end
    end
  end

  # Updates a object in the db using provided table and object
  #
  # object - Object to be updated
  # table - DB table to update (String)
  #
  # Returns nothing
  def update(object, table)
    variables = object.instance_variables
    values = []
    query = "UPDATE #{table} SET "
    count = 0
    variables.each_with_index do |var, _index|
      next unless object.instance_variable_get(var).is_a?(String) ||
                  object.instance_variable_get(var).is_a?(Integer) ||
                  object.instance_variable_get(var).nil?

      query += if count.zero?
                 " #{var.to_s.gsub('@', '')} = ?"
               else
                 ", #{var.to_s.gsub('@', '')} = ?"
               end
      values << object.instance_variable_get(var)
      count += 1
    end
    query += ' WHERE id = ?'
    values << object.instance_variable_get(:@id)
    DBHandler.execute(query, values.flatten[0..-1])
  end

  # Fetches all entries given a table (Alternative)
  #
  # Returns returned object or Array of Objects
  def self.all
    fetch_all
  end

  # Fetches all entries given a table
  #
  # Returns returned object or Array of Objects
  def self.fetch_all
    sql_operator(
      table: @table,
      join: @tables,
      select: @columns
    )
  end

  # Removes an element from the database based on the id
  #
  # Returns nothing
  def delete
    table = if @table.nil?
              self.class.table
            else
              @table
            end
    execute("DELETE FROM #{table} WHERE id = ?", id)
  end

  # Deletes elements from the database where the condition applies
  #
  # args - Where areguments
  #
  # Returns nothing
  def delete_where(args)
    self.class.delete_where(args, self.class.table)
  end

  # Deletes elements from the database where the condition applies
  #
  # args- Where arguments
  # table - Optional (String, Symbol) of table todo delete from
  #
  # Returns nothing
  def self.delete_where(args, table = nil)
    table = @table if table.nil?

    where = where_constructor(args, table.to_s)
    execute("DELETE FROM #{table} #{where.first}", where.last)
  end

  # Fetches a entry based on the id
  #
  # id - (Integer, String, Symbol) ID of row to fetch
  # table - (String, Symbol) Optional table to fetch from.
  #
  # Returns the object
  def self.fetch_by_id(id, table = nil)
    table = @table if table.nil?
    raise 'Provided table is invalid' unless table.is_a?(String) || table.is_a?(Symbol)

    sql_operator table: @table, where: "#{table}.id = #{id}", join: @tables, select: @columns
  end

  # Fetches a entry based on the id (Alternative)
  #
  # id - (Integer, String, Symbol) ID of row to fetch
  # table - (String, Symbol) Optional table to fetch from.
  #
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
  # params - Where params (Array - Hash, String)
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
  # data - (Hash) Containing data
  # table - String (Optional)
  #
  # Returns nothing
  def insert(data, table = nil)
    table = @table if table.nil?
    if table.downcase.include?('connector') && !table.downcase.include?('_')
      table.downcase.split('connector')
      table = table.downcase.split('connector').first + '_' + 'connector'
    end
    insert!(data, table)
  end

  # Decides if the provided argument has to be processed before execution
  #
  # args - Custom arguments to pass to the method
  #
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
  # array - Array of Hashes or Array containing a Hash containing data
  # class_holder - "Origin" instance (Object)
  #
  # Returns nothing

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.object_constructor(array, class_holder)
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
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
  # value - (String, Array, Symbol) Select columns
  # table - (String, Symbol) Select from table
  #
  # Returns selects as SQL - Query (Partial string)
  def self.select_constructor(value, table) # rubocop:disable Metrics/AbcSize
    selects = 'SELECT'
    raise 'No columns provided' if value.nil?

    if value.is_a?(Symbol) || value.is_a?(String)
      selects = "SELECT #{value} FROM #{table}"
    else
      # Adds additional selects from joined tables
      unless @tables.nil?
        added = []
        @tables.flatten.each do |table| # rubocop:disable Lint/ShadowingOuterLocalVariable
          if table.is_a? Hash
            table.each do |hash|
              hash.flatten.each do |r|
                if r.to_s.downcase.include?('connector')
                  r = r.to_s.downcase.gsub('_', '').capitalize
                  r[-9] = 'C'
                else
                  r = r.to_s.downcase.capitalize
                end
                next unless class_exists?(r) && to_s.downcase != r.to_s.downcase
                break if added.include?(r)

                value << Object.const_get(r).columns
                added << r
              end
            end
          else
            if table.to_s.downcase.include?('connector')
              table = table.to_s.downcase.gsub('_', '').capitalize
              table[-9] = 'C'
            else
              table = table.to_s.downcase.capitalize
            end
            if class_exists?(table) && to_s.downcase != table.to_s.downcase
              break if added.include?(table)

              value << Object.const_get(table).columns
              added << table
            end
          end
        end
      end
      # Processes columns
      value.flatten.each do |item|
        set = false
        item.to_s.split(' ').each { |z| set = true if z.downcase == 'as' }
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
  # value - (Array, Hash, String) SQL where params/ params as hash
  # table - (String, Key/Symbol) Table for where the condition applies
  #
  # Reutrns a Array containing wheres as SQL - Query (Partial String), and associated values
  def self.where_constructor(value, table) # rubocop:disable Metrics/CyclomaticComplexity
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
      # rubocop:disable Style/DoubleNegation
      keys.each_with_index do |key, index|
        if value[key].is_a?(String) || value[key].is_a?(Integer) ||
           value[key].is_a?(Symbol) || !!value[key] == value[key] # Boolean?
          # rubocop:enable Style/DoubleNegation
          temp = value[key]
          temp = temp.to_s if temp.is_a? Symbol
          key = "#{table}.id" if key.to_s.downcase == 'id'
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
      value.each_with_index do |value, i| # rubocop:disable Lint/ShadowingOuterLocalVariable
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
  # joins - Tables to join (Array, Hash, String, Key)
  # talbe - Table to join on (Key, String)
  # type - (String, Key) Optional type of join param
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
  # value - (Hash) Hash containing table and or order
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

  # Checks if a class is defined
  #
  # class_name - (String) Class name. Case sensetive
  #
  # Returns true or false
  def self.class_exists?(class_name)
    klass = Module.const_get(class_name)
    klass.is_a?(Class)
  rescue NameError
    false
  end

  # Constructs the additional joines from joined in tables.
  #
  # tables - Join hash/array/string/key
  #
  # Returns the additional joins from a given class (String)
  def self.additional_join(tables) # rubocop:disable Metrics/AbcSize
    return '' if tables.nil?

    query = ''
    tables.each do |table|
      if table.is_a? String
        if class_exists?(table.downcase.capitalize) && to_s.downcase != table.downcase
          query += join_constructor(Object.const_get(table.downcase.capitalize).tables, table.downcase)
          query += additional_join(Object.const_get(table.to_s.downcase.capitalize).tables)
        end
      elsif table.is_a? Symbol
        if class_exists?(table.to_s.downcase.capitalize) && to_s.downcase != table.to_s.downcase
          query += join_constructor(Object.const_get(table.to_s.downcase.capitalize).tables,
                                    Object.const_get(table.to_s.downcase.capitalize).table)
          query += additional_join(Object.const_get(table.to_s.downcase.capitalize).tables)
        end
      elsif table.is_a? Hash
        temp = if class_exists?(table.to_s.downcase.capitalize) && to_s.downcase != table.to_s.downcase
                 table.to_s.downcase.capitalize
               elsif table.to_s.downcase.include?('connector')
                 if class_exists?(table.to_s.split('_')[0].downcase.capitalize) &&
                    to_s.downcase != table.to_s.downcase
                   table.to_s.split('_')[0].downcase.capitalize
                 else
                   ''
                 end
               else
                 ''
               end
        query += if temp == ''
                   additional_join(table.first)
                 else
                   join_constructor(Object.const_get(temp).tables, table.to_s.downcase)
                 end
      elsif table.is_a? Array
        query += additional_join table
      end
    end
    query
  end

  # Acts as manager for construction of SQL queries
  #
  # args - (Hash) Hash of 'arguments' to be constructed and then executed
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
        join += additional_join(value)
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
  # data -(Hash) containing data to insert
  # table - (String/Key) database table to insert into
  #
  # Reuturns the new id
  private def insert!(data, table) # rubocop:disable Style/AccessModifierDeclarations
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
      execute_transaction(query + values, stored)
    end
  end

  # Writes an object into a given table
  #
  # table - String (Name of table)
  # object - Object to be written to table
  #
  # Returns nothing
  private def write_to_db(object, table) # rubocop:disable Style/AccessModifierDeclarations
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

    execute_transaction("INSERT INTO #{table} (#{k}) VALUES (#{x})", q)
  end

  # Executes given sql query like SQLite3 gem
  #
  # sql - String (SQL query)
  # values - Array containing a list of values (optional)
  #
  # Returns sqlresult as hash
  def self.execute(sql, *values)
    # p '__________________________'
    # p sql
    # p values
    @db ||= DBHandler.connect
    if values == []
      @db.execute(sql)
    elsif values[0].is_a? Array
      @db.execute(sql, values[0][0..-1])
    else
      @db.execute(sql, values[0..-1])
    end
  end

  # Executes given sql query like SQLite3 gem
  #
  # sql - Sql Query (String)
  # values - Array containing a list of values (optional)
  #
  # Returns id or sqlresult as hash
  def execute_transaction(sql, *values)
    # p '__________________________'
    # p sql
    # p values
    # Inserts
    @db ||= DBHandler.connect
    begin
      @db.transaction
      if values == []
        @db.execute(sql)
      elsif values[0].is_a? Array
        @db.execute(sql, values[0][0..-1])
      else
        @db.execute(sql, values[0..-1])
      end

      # Fetches the new id for inserted row
      if sql.include?('INSERT') && !sql.downcase.include?('connector')
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
    rescue SQLite3::Exception => e
      puts 'Exception occurred'
      puts e
      @db.rollback
      return 'An error occured when trying to write data to database'
    end

    return id unless id.nil?
  end
end
