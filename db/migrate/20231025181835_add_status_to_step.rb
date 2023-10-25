class AddStatusToStep < ActiveRecord::Migration[7.1]
  def change
    add_column :steps, :status, :integer, null: false, default: 0
  end
end
