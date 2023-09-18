class CreatePlaces < ActiveRecord::Migration[7.0]
  def change
    create_table :places do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.boolean :enabled, null: false, default: true
      t.datetime :archived_at

      t.timestamps
    end
  end
end
