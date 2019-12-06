# frozen_string_literal: true

require 'sqlite3'

# Handles seeding/generation of db
class Seeder

  # Seeds the database
  def self.seed!
    db = connect
    drop_tables(db)
    puts 'Deleted old tables'
    create_tables(db)
    puts 'Created new tables'
    populate_tables(db)
    puts 'Populated tables'
  end

  # Connects to the db
  def self.connect
    SQLite3::Database.new 'db/data.db'
  end

  # Drops tables if they excist
  # 
  # db - (database Object)
  def self.drop_tables(db)
    db.execute('DROP TABLE IF EXISTS tickets;')
    db.execute('DROP TABLE IF EXISTS train_types;')
    db.execute('DROP TABLE IF EXISTS trains;')
    db.execute('DROP TABLE IF EXISTS seats;')
    db.execute('DROP TABLE IF EXISTS seats_connector;')
    db.execute('DROP TABLE IF EXISTS services;')
    db.execute('DROP TABLE IF EXISTS destinations;')
    db.execute('DROP TABLE IF EXISTS bookings;')
    db.execute('DROP TABLE IF EXISTS users;')
    db.execute('DROP TABLE IF EXISTS platforms;')
    db.execute('DROP TABLE IF EXISTS connector;')
    db.execute('DROP TABLE IF EXISTS booking_connector;')
  end

  # Creates tables in the db
  # 
  # db - (database Object)
  def self.create_tables(db)
    db.execute <<-SQL
            CREATE TABLE "tickets" (
                "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"  TEXT NOT NULL,
                "price" INTEGER NOT NULL,
                "points" INTEGER NOT NULL
            );
    SQL

    db.execute <<-SQL
            CREATE TABLE "train_types" (
                "id"	         INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"	         TEXT NOT NULL,
                "kiosk"          INTEGER NOT NULL,
                "capacity"       INTEGER NOT NULL
            );
    SQL

    db.execute <<-SQL
            CREATE TABLE "trains" (
                "id"      INTEGER PRIMARY KEY AUTOINCREMENT,
                "type_id" INTEGER NOT NULL,
                "status"  TEXT NOT NULL DEFAULT "operational",
                "main_location"  TEXT NOT NULL DEFAULT "Göteborg C"
            );
    SQL

    db.execute <<-SQL
            CREATE TABLE "seats" (
                "id"                INTEGER PRIMARY KEY AUTOINCREMENT,
                "service_id"        INTEGER NOT NULL,
                "occupied"          INTEGER NOT NULL DEFAULT 0,
                "booking_id"        INTEGER NOT NULL DEFAULT 0
            );
    SQL

    db.execute <<-SQL
            CREATE TABLE "services" (
                "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
                "train_id"              INTEGER NOT NULL,
                "name"                  TEXT NOT NULL,
                "departure_id"          INTEGER NOT NULL,
                "departure_time"        TEXT NOT NULL,
                "arrival_id"            INTEGER NOT NULL,
                "arrival_time"          TEXT NOT NULL,
                "empty_seats"           INTEGER NOT NULL
            );
    SQL

    db.execute <<-SQL
            CREATE TABLE "destinations" (
                "id"            INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"          TEXT NOT NULL
                );
    SQL

    db.execute <<-SQL
            CREATE TABLE "bookings" (
                "id"                INTEGER PRIMARY KEY AUTOINCREMENT,
                "user_id"           INTEGER,
                "price"             INTEGER NOT NULL,
                "service_id"        INTEGER NOT NULL,
                "booking_time"      TEXT NOT NULL,
                "status"            INTEGER NOT NULL,
                "session_id"        TEXT
                );
    SQL

    db.execute <<-SQL
            CREATE TABLE "booking_connector" (
                "booking_id"        INTEGER NOT NULL,
                "ticket_id"         INTEGER,
                "amount"            INTEGER NOT NULL
                );
    SQL

    db.execute <<-SQL
            CREATE TABLE "seats_connector" (
                "seat_id"              INTEGER NOT NULL,
                "service_id"           INTEGER NOT NULL,
                "booking_id"           INTEGER NOT NULL
                );
    SQL

    db.execute <<-SQL
            CREATE TABLE "users" (
                "id"                INTEGER PRIMARY KEY AUTOINCREMENT,
                "first_name"        TEXT NOT NULL,
                "last_name"         TEXT NOT NULL,
                "password"          TEXT NOT NULL,
                "email"             TEXT NOT NULL UNIQUE,
                "points"            INTEGER NOT NULL DEFAULT 0,
                "admin"             INTEGER NOT NULL DEFAULT 0
                );
    SQL

    db.execute <<-SQL
            CREATE TABLE "platforms" (
                "id"                INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"              TEXT NOT NULL,
                "destination_id"    INTEGER NOT NULL
                );
    SQL

    db.execute <<-SQL
            CREATE TABLE "connector" (
                "ticket_id"               INTEGER NOT NULL,
                "service_id"              INTEGER NOT NULL
                );
    SQL
  end

  # Populates tables with data
  # 
  # db - (database Object)
  def self.populate_tables(db)
    connector = [
      {ticket_id: 1, service_id: 1},
      {ticket_id: 1, service_id: 2},
      {ticket_id: 1, service_id: 3},
      {ticket_id: 1, service_id: 4},
      {ticket_id: 2, service_id: 2},
      {ticket_id: 2, service_id: 3},
      {ticket_id: 2, service_id: 4},
      {ticket_id: 3, service_id: 4},
      {ticket_id: 4, service_id: 4},
      {ticket_id: 4, service_id: 2},
      {ticket_id: 4, service_id: 1}
    ]

    tickets = [
      { name: '1a Klass +', price: 380, points: 100 },
      { name: '1a Klass', price: 250, points: 100 },
      { name: '2a Klass', price: 150, points: 70 },
      { name: '2a Klass Barn', price: 70, points: 50 }
    ]

    train_types = [
      { name: 'X7', kiosk: 1, seats: 300 },
      { name: 'BR142', kiosk: 1, seats: 421 },
      { name: 'X10', kiosk: 0, seats: 152 }
    ]

    destinations = [
      { name: 'Göteborg C' },
      { name: 'Stockholm C' },
      { name: 'Örebro C' }
    ]

    platforms = [
      { name: '1', destination_id: 1 },
      { name: '1 Yttre', destination_id: 1 },
      { name: '2', destination_id: 1 },
      { name: '3', destination_id: 1 },
      { name: '4', destination_id: 1 },
      { name: '1', destination_id: 2 },
      { name: '1', destination_id: 3 }
    ]

    services = [
      {train_id: '1', name: 'Express', departure_id: 1, departure_time: DateTime.now.to_time.to_i, arrival_id: 2, arrival_time: (DateTime.now + 1).to_time.to_i, empty_seats: 120},
      {train_id: '2', name: 'Snabb', departure_id: 1, departure_time: (DateTime.now+2).to_time.to_i, arrival_id: 2, arrival_time: (DateTime.now + 3).to_time.to_i, empty_seats: 120},
      {train_id: '2', name: 'Snabbare', departure_id: 1, departure_time: (DateTime.now + 1).to_time.to_i, arrival_id: 3, arrival_time: (DateTime.now + 2).to_time.to_i, empty_seats: 120},
      {train_id: '2', name: 'Snabb Express delux', departure_id: 1, departure_time: DateTime.now.to_time.to_i, arrival_id: 2, arrival_time: (DateTime.now + 2).to_time.to_i, empty_seats: 120}
    ]

    seats = [
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 3},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 1},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2},
      {service_id: 2}
    ]

    trains = [
      {type_id: 1},
      {type_id: 2},
      {type_id: 2},
      {type_id: 1},
      {type_id: 3},
      {type_id: 2},
      {type_id: 2},
      {type_id: 1},
      {type_id: 2},
      {type_id: 4},
      {type_id: 4},
      {type_id: 4},
      {type_id: 2}
    ]

    seats.each do |d|
      db.execute('INSERT INTO seats (service_id) VALUES (?)', d[:service_id])
    end

    trains.each do |d|
      db.execute('INSERT INTO trains (type_id) VALUES (?)', d[:type_id])
    end

    connector.each do |d|
      db.execute('INSERT INTO connector (service_id, ticket_id) VALUES (?,?)', d[:service_id], d[:ticket_id])
    end

    services.each do |d|
      db.execute('INSERT INTO services (train_id, name, departure_id, departure_time, arrival_id, arrival_time, empty_seats) VALUES (?,?,?,?,?,?,?)', d[:train_id], d[:name], d[:departure_id], d[:departure_time], d[:arrival_id], d[:arrival_time], d[:empty_seats])
    end

    tickets.each do |d|
      db.execute('INSERT INTO tickets (name, price, points) VALUES(?,?,?)', d[:name], d[:price], d[:points])
    end

    train_types.each do |d|
      db.execute('INSERT INTO train_types (name, kiosk, capacity) VALUES(?,?,?)', d[:name], d[:kiosk], d[:seats])
    end

    destinations.each do |d|
      db.execute('INSERT INTO destinations (name) VALUES(?)', d[:name])
    end

    platforms.each do |d|
      db.execute('INSERT INTO platforms (name, destination_id) VALUES(?, ?)', d[:name], d[:destination_id])
    end
  end
end

Seeder.seed!
