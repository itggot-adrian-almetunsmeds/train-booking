# frozen_string_literal: true

require_relative 'db_handler'

# Handles all services
class Service < DBHandler
  set_table :service
  set_columns :id, :train_id, :name, :departure_id, :departure_time,
              :arrival_id, :arrival_time, :empty_seats, 'dep.name', 'arr.name'
  has_a ['destination AS dep ON dep.id = service.departure_id',
         'destination AS arr ON arr.id = service.arrival_id']
  # has_a ticket_connector: :ticket

  def tickets(id = nil)
    p self.id
    if id.nil?
      p Ticket.fetch_where service_id: self.id
    else
      p Ticket.fetch_where 'ticket.id': id
    end
  end

  def self.update_empty_seats(id)
    execute 'UPDATE services SET empty_seats = (SELECT COUNT(occupied) FROM seats WHERE service_id = ? AND occupied = 0) WHERE id = ?', id, id
  end

  def self.search(params)
    params['dep'] = '%' + params['dep'] + '%'
    params['arr'] = '%' + params['arr'] + '%'
    params['time'] = DateTime.parse(params['time']).to_time.to_i
    x = fetch_where ["dep.name LIKE #{params['dep']}", "arr.name LIKE #{params['arr']}",
                     "departure_time > #{params['time']}"]

    if x == []
      'No available services'
    else
      p x
      x.flatten if x.is_a? Array
    end
  end

  # def self.tickets(id)
  #   DBHandler.execute('SELECT * FROM connector JOIN tickets ON tickets.id = connector.ticket_id ' \
  #     'WHERE connector.service_id = ?', id)
  # end
end
