class CreateMissions < ActiveRecord::Migration[7.0]
  def change
    create_table :missions do |t|
      t.time :drop_time
      t.integer :drop_duration
      t.integer :position, null: false, default: 1
      t.references :customer, null: false
      t.references :place, null: false
      t.references :daily_quest, null: false

      t.timestamps
    end
  end
end
