# frozen_string_literal: true

require_relative 'db_handler'

# Handles all services
class Service < DBHandler
  set_table :service
  set_columns :id, :train_id, :name, :departure_id, :departure_time,
              :arrival_id, :arrival_time, :empty_seats, :'dep.name', :'arr.name',
              :'arr_plattform.name', :'dep_plattform.name'

  has_a ['platform as arr_plattform on service.arrival_id = arr_plattform.id',
         'platform as dep_plattform on service.departure_id = dep_plattform.id',
         'destination AS dep ON dep.id = dep_plattform.destination_id',
         'destination AS arr ON arr.id = arr_plattform.destination_id',
         :train]

  # Fetches a ticket based on service id unless id is provided
  #
  # id - Ticket ID Optional (Integer)
  #
  # Returns a ticket Object
  def tickets(id = nil)
    if id.nil?
      Ticket.fetch_where service_id: self.id
    else
      Ticket.fetch_where 'ticket.id': id
    end
  end

  # Updates empty seats for a given service and saves it to the db
  #
  # id - Service id (Integer)
  #
  # Returns nothing
  def self.update_empty_seats(id)
    service = Service.fetch_where id: id
    temp = Seat.fetch_where service_id: id, occupied: 0
    amount = if temp.is_a? Array
               temp.length
             else
               1
             end
    service.empty_seats = amount
    service.save
  end

  # Searches for services meeting given params
  #
  # params - (Hash) time: dep: arr:
  #
  # Returns Service Objects in array or a single Object
  #   depending on results
  def self.search(params)
    params['dep'] = '%' + params['dep'] + '%'
    params['arr'] = '%' + params['arr'] + '%'
    params['time'] = DateTime.parse(params['time']).to_time.to_i
    x = fetch_where ["dep.name LIKE #{params['dep']}", "arr.name LIKE #{params['arr']}",
                     "departure_time > #{params['time']}", 'empty_seats != 0']

    return 'No available services' if x == []

    return x.flatten if x.is_a? Array

    x
  end
end
