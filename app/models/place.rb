class Place < ApplicationRecord
  include Archivable
  include Optionable

  normalizes :email, with: -> { _1.strip.downcase }

  belongs_to :company
  has_one :address, as: :addressable, dependent: :destroy
  has_many :missions, dependent: :destroy

  accepts_nested_attributes_for :address, reject_if: :all_blank

  has_one_attached :photo
  has_rich_text :details

  validates :name, presence: true
  validates :phone, presence: true, if: :mandatory_phone?
  validates :phone,
            numericality: true,
            length: { is: 10 },
            allow_blank: -> { !mandatory_phone? }
  validates :address, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :by_query, lambda { |query|
    joins(:address)
      .where('"places"."name" ILIKE ?', "%#{query}%")
      .or(where('"addresses"."label" ILIKE ?', "%#{query}%"))
  }

  after_create :assign_photo, unless: -> { photo.present? }

  private

  def assign_photo
    url = "https://ui-avatars.com/api/?format=jpg&name=#{I18n.transliterate(name)}&background=3b82f6&color=ffffff&size=256"

    photo.attach(io: URI.parse(url).open, filename: 'place.jpg')
  end

  def mandatory_phone?
    options.validate_phone_for_places?
  end
end

# == Schema Information
#
# Table name: places
#
#  id          :bigint(8)        not null, primary key
#  name        :string
#  phone       :string
#  email       :string
#  enabled     :boolean          default(TRUE), not null
#  archived_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint(8)
#
# Indexes
#
#  index_places_on_company_id  (company_id)
#
