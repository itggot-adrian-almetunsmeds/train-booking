# frozen_string_literal: true

require 'sqlite3'

class Seeder
  def self.seed!
    db = connect
    drop_tables(db)
    puts 'Deleted old tables'
    create_tables(db)
    puts 'Created new tables'
    populate_tables(db)
    puts 'Populated tables'
  end

  def self.connect
    SQLite3::Database.new 'db/data.db'
  end

  def self.drop_tables(db)
    db.execute('DROP TABLE IF EXISTS tickets;')
    db.execute('DROP TABLE IF EXISTS train_types;')
    db.execute('DROP TABLE IF EXISTS trains;')
    db.execute('DROP TABLE IF EXISTS seats;')
    db.execute('DROP TABLE IF EXISTS services;')
    db.execute('DROP TABLE IF EXISTS destinations;')
    db.execute('DROP TABLE IF EXISTS bookings;')
    db.execute('DROP TABLE IF EXISTS users;')
    db.execute('DROP TABLE IF EXISTS platforms;')
  end

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
                "booking_id"        INTEGER NOT NULL
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
                "user_id"           INTEGER NOT NULL,
                "price"             INTEGER NOT NULL,
                "service_id"        INTEGER NOT NULL,
                "booking_time"      TEXT NOT NULL
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
  end

  def self.populate_tables(db)
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
