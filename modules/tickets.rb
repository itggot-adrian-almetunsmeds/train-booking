# frozen_string_literal: true

require_relative 'db_handler'

# TODO: Tickets are not joined in on /checkout page

class Ticket_connector < DBHandler
  set_table :ticket_connector
  set_columns :ticket_id, :service_id
  has_a :ticket
end
# Handles everything relating to tickets
class Ticket < DBHandler
  set_table :ticket
  set_columns :price, :name, :id, :points

  def self.fetch_where(params)
    Ticket_connector.fetch_where params
  end
end
