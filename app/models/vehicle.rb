class Vehicle < ApplicationRecord
  enum status: { normal: 0, breakdown: 1, mechanic: 2 }

  belongs_to :company
  has_one :transporter, dependent: :nullify

  has_one_attached :photo
  has_rich_text :details

  humanize :status, enum: true

  validates :name, presence: true
  validates :number_plate, presence: true, uniqueness: true
  validates :max_regular_seats, presence: true, numericality: { only_integer: true }
  validates :max_wheelchair_seats, presence: true, numericality: { only_integer: true }

  scope :enabled, -> { where(enabled: true) }

  after_create :assign_photo, unless: -> { photo.present? }
  before_update :unassign_transporter, if: :unavailable_vehicle?

  private

  def assign_photo
    url = "https://ui-avatars.com/api/?format=jpg&name=#{I18n.transliterate(name)}&size=256"

    photo.attach(io: URI.parse(url).open, filename: 'vehicle.jpg')
  end

  def unassign_transporter
    self.transporter = nil
  end

  def unavailable_vehicle?
    status_changed?(to: :breakdown) || status_changed?(to: :mechanic)
  end
end

# == Schema Information
#
# Table name: vehicles
#
#  id                   :bigint(8)        not null, primary key
#  name                 :string
#  number_plate         :string
#  width                :float
#  height               :float
#  length               :float
#  max_regular_seats    :integer          default(0), not null
#  max_wheelchair_seats :integer          default(0), not null
#  status               :integer          default("normal"), not null
#  substitution         :boolean          default(FALSE), not null
#  enabled              :boolean          default(TRUE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_id           :bigint(8)
#
# Indexes
#
#  index_vehicles_on_company_id    (company_id)
#  index_vehicles_on_number_plate  (number_plate) UNIQUE
#
