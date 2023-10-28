class Company < ApplicationRecord
  attr_accessor :virtual_address

  has_one :setting, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :daily_quests, dependent: :destroy
  has_many :places, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :transporters, dependent: :destroy
  has_many :vehicles, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  has_one_attached :logo
  has_one_attached :background_cover

  has_rich_text :description

  after_create do
    if virtual_address.present?
      address = Address.new(label: virtual_address)
      create_setting!(address: address)
    else
      create_setting!
    end
  end
end

# == Schema Information
#
# Table name: companies
#
#  id         :bigint(8)        not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_companies_on_name  (name) UNIQUE
#
