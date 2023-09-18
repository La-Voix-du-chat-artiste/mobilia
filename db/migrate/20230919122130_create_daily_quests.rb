class CreateDailyQuests < ActiveRecord::Migration[7.0]
  def change
    create_table :daily_quests do |t|
      t.date :started_on
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
