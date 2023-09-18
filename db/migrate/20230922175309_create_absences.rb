class CreateAbsences < ActiveRecord::Migration[7.0]
  def change
    create_table :absences do |t|
      t.date :started_on
      t.date :ended_on
      t.integer :reason, null: false, default: 0
      t.references :transporter, null: false

      t.timestamps
    end
  end
end
