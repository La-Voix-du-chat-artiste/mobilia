class CreateSteps < ActiveRecord::Migration[7.0]
  def change
    create_table :steps do |t|
      t.string :title
      t.datetime :started_at
      t.datetime :arrival_at
      t.integer :departure_point_icon, null: false, default: 0
      t.integer :arrival_point_icon, null: false, default: 0
      t.integer :role, null: false, default: 0
      t.json :route, null: false, default: {}
      t.references :transporter
      t.references :mission, null: false

      t.timestamps
    end
  end
end
