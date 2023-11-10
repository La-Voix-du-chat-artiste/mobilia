class AddUniqueIndexScopedByCompanyToUser < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, :email
    add_index :users, %i[email company_id], unique: true
  end
end
