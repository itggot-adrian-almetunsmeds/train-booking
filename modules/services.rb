# frozen_string_literal: true

require_relative 'db_handler'

# Handles all services
class Service < DBHandler
  def self.all
    super('services')
  end

  def self.with_id(id)
    super('services', id)
  end

  def self.update_empty_seats(id)
    execute 'UPDATE services SET empty_seats = (SELECT COUNT(occupied) FROM seats WHERE service_id = ? AND occupied = 0) WHERE id = ?', id, id
  end

  # rubocop:disable Metrics/MethodLength
  def self.search(params) # rubocop:disable Metrics/AbcSize
    params['dep'] = '%' + params['dep'] + '%'
    params['arr'] = '%' + params['arr'] + '%'
    params['time'] = DateTime.parse(params['time']).to_time.to_i
    dep = DBHandler.execute('SELECT * FROM destinations WHERE name LIKE ?', params['dep'])
    arr = DBHandler.execute('SELECT * FROM destinations WHERE name LIKE ?', params['arr'])
    x = DBHandler.execute('SELECT * FROM services WHERE departure_id = ? AND arrival_id = ? ' \
      'AND departure_time > ?', [dep.first['id'], arr.first['id'], params['time']])
    if x.empty? # rubocop:disable Style/GuardClause
      return 'No such data'
    elsif x.is_a? Array
      x.first['departure'] = dep.first['name']
      x.first['arrival'] = arr.first['name']
      return x
    else
      x['departure'] = dep.first['name']
      x['arrival'] = arr.first['name']
      return x
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.tickets(id)
    DBHandler.execute('SELECT * FROM connector JOIN tickets ON tickets.id = connector.ticket_id ' \
      'WHERE connector.service_id = ?', id)
  end
end
