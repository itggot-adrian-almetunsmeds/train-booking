# frozen_string_literal: true

require_relative 'db_handler'

# Handles the train connector
class Train_type < DBHandler # rubocop:disable Naming/ClassAndModuleCamelCase
  set_table :train_type
  set_columns :id, :name, :kiosk, :capacity
end

# Handles trains
class Train < DBHandler
  set_table :train
  has_a :train_type
  set_columns :id, :train_type_id, :status, :main_location
end
