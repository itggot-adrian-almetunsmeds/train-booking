# frozen_string_literal: true

require_relative 'db_handler'

class Service < DBHandler
  def self.all
    super('services')
  end

  def self.search(params)
    params['dep'] = '%' + params['dep'] + '%'
    params['arr'] = '%' + params['arr'] + '%'
    params['date'] = Time.parse(params['date']).to_time.to_i
    dep = DBHandler.execute('SELECT * FROM destinations WHERE name LIKE ?', params['dep'])
    arr = DBHandler.execute('SELECT * FROM destinations WHERE name LIKE ?', params['arr'])
    x = DBHandler.execute('SELECT * FROM services WHERE departure_id = ? AND arrival_id = ? AND departure_time > ?', [dep.first['id'], arr.first['id'], params['date']])
    p x
    if x.is_a? Array
      x.first['departure'] = dep.first['name']
      x.first['arrival'] = arr.first['name']
    else
      x['departure'] = dep.first['name']
      x['arrival'] = arr.first['name']
    end
    x
  end

  def self.filter_dep_time(time); end
end
