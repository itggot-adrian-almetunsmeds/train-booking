# frozen_string_literal: true

require_relative 'db_handler'

# Handles everything relating to tickets
class Ticket < DBHandler
  set_table :ticket_connector
  set_columns :ticket_id, :service_id, 'ticket.price', 'ticket.name', 'ticket.id', 'ticket.points'
  has_a [:ticket]
end
