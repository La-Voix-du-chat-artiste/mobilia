class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.json :options, null: false, default: {}
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
