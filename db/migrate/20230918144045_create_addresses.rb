class CreateAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :addresses do |t|
      t.string :label
      t.string :street
      t.string :postcode
      t.string :town
      t.string :country
      t.float :latitude
      t.float :longitude
      t.references :addressable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
