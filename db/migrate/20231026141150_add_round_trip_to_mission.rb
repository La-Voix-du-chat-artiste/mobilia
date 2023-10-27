class AddRoundTripToMission < ActiveRecord::Migration[7.1]
  def change
    add_column :missions, :round_trip, :boolean, null: false, default: true
  end
end
