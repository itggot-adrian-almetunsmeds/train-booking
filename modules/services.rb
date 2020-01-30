# frozen_string_literal: true

require_relative 'db_handler'

# Handles all services
class Service < DBHandler
  set_table :service
  set_columns :id, :train_id, :name, :departure_id, :departure_time,
              :arrival_id, :arrival_time, :empty_seats, :'dep.name', :'arr.name',
              :'arr_plattform.name', :'dep_plattform.name'

  has_many :platform, :arr_plattform, 'service.arrival_id = arr_plattform.id'
  has_many :platform, :dep_plattform, 'service.departure_id = dep_plattform.id'
  has_many :destination, :dep, 'dep.id = dep_plattform.destination_id'
  has_many :destination, :arr, 'arr.id = arr_plattform.destination_id'

  has_a :train

  # Saves a new service or updates it
  #
  # Returns id if creating a new object
  def save(new_ = false)
    super()
    if new_
      train = Train.fetch_where id: train_id
      train.train_type.capacity.to_i.times do
        Seat.new(service_id: id, occupied: 0, booking_id: 0).save
      end
    end
    id
  end

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
