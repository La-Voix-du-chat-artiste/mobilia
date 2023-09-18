class AddCompanyIdToModels < ActiveRecord::Migration[7.1]
  def change
    add_reference :customers, :company
    add_reference :daily_quests, :company
    add_reference :places, :company
    add_reference :users, :company
    add_reference :vehicles, :company
  end
end
