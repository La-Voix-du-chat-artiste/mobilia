class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :email
      t.integer :kind, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.datetime :archived_at
      t.references :favorite_trip_transporter
      t.references :favorite_trip_back_transporter

      t.timestamps
    end
  end
end
