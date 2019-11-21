# frozen_string_literal: true

require_relative 'db_handler'

class Service < DBHandler
  def self.all
    super('services')
  end

  def self.with_id(id)
    super('services', id)
  end

  def self.search(params)
    params['dep'] = '%' + params['dep'] + '%'
    params['arr'] = '%' + params['arr'] + '%'
    params['time'] = DateTime.parse(params['time']).to_time.to_i
    dep = DBHandler.execute('SELECT * FROM destinations WHERE name LIKE ?', params['dep'])
    arr = DBHandler.execute('SELECT * FROM destinations WHERE name LIKE ?', params['arr'])
    x = DBHandler.execute('SELECT * FROM services WHERE departure_id = ? AND arrival_id = ? AND departure_time > ?', [dep.first['id'], arr.first['id'], params['time']])
    if x.empty?
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

  def self.tickets(id)
    x = DBHandler.execute('SELECT * FROM connector JOIN tickets ON tickets.id = connector.ticket_id WHERE connector.service_id = ?', id)
  end
end
