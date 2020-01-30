# frozen_string_literal: true

# Configures Platforms
class Platform < DBHandler
  set_table :platform
  has_a :destination
  set_columns :id, :name, :destination_id
end
