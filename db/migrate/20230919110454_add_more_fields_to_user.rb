class AddMoreFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :type
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.integer :role, null: false, default: 0
      t.json :availabilities, null: false, default: {}
      # t.time :started_time
      # t.time :ended_time
      t.datetime :archived_at
      t.references :vehicle
    end
  end
end
