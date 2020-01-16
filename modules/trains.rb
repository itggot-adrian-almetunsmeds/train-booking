# frozen_string_literal: true

require_relative 'db_handler'
# Handles trains
class Train < DBHandler
  attr_reader :status, :main_location, :type_id, :id
  attr_writer :status, :main_location, :type_id

  # Creates a new train
  def initialize(id = nil)
    if id.nil?
      @status = 'operational'
      @main_location = "G\xC3\xB6teborg C"
      @type_id = 0
      @id = (DBHandler.write_to_db 'trains', self)['id']
    else
      temp = DBHandler.with_id('trains', id)
      @status = temp['status']
      @main_location = temp['main_location']
      @type_id = temp['type_id']
      @id = temp['id']
    end
  end

  # Retrives data from trains table
  #
  # Returns data from trains table as hash
  def self.all
    super('trains')
  end

  def save
    super('trains', self)
  end
end

# x = Train.new(34)
# p x
# x.type_id = 5
# x.save
