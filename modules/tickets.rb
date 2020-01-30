# frozen_string_literal: true

require_relative 'db_handler'

# Configures ticket connector
class Ticket_connector < DBHandler # rubocop:disable Naming/ClassAndModuleCamelCase
  set_table :ticket_connector
  set_columns :ticket_id, :service_id
  has_a :ticket
end

# Handles everything relating to tickets
class Ticket < DBHandler
  set_table :ticket
  set_columns :price, :name, :id, :points

  # Fetches where params are meet
  #
  # params - Hash of values to ==, or string of conditions or array of previous
  #
  # Returns object or array of objects where params apply
  def self.fetch_where(params)
    Ticket_connector.fetch_where params
  end
end
