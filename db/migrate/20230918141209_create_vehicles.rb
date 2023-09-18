class CreateVehicles < ActiveRecord::Migration[7.0]
  def change
    create_table :vehicles do |t|
      t.string :name
      t.string :number_plate
      t.float :width
      t.float :height
      t.float :length
      t.integer :max_regular_seats, null: false, default: 0
      t.integer :max_wheelchair_seats, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.boolean :substitution, null: false, default: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :vehicles, :number_plate, unique: true
  end
end
