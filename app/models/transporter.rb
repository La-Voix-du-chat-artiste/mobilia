class Transporter < User
  include Archivable

  attr_accessor :longitude, :latitude, :driving, :address_label

  attribute :availabilities, AvailabilitiesOption.to_type

  belongs_to :vehicle, optional: true
  has_one :address, as: :addressable, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :steps, dependent: :nullify

  accepts_nested_attributes_for :address, reject_if: :all_blank

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :address, presence: true
  validates :phone, presence: true, numericality: true, length: { is: 10 }
  validates :vehicle, allow_blank: true, uniqueness: true

  after_create :assign_photo, unless: -> { photo.present? }

  def off?(date = Date.current)
    absences.present_today?(date)
  end

  def no_vehicle?
    vehicle.nil?
  end

  def current_absence(date = Date.current)
    absences
      .not_attending
      .where('started_on <= :date AND ended_on >= :date', date: date)
      .last
  end

  private

  def assign_photo
    url = "https://ui-avatars.com/api/?format=jpg&name=#{I18n.transliterate(first_name).first}+#{I18n.transliterate(last_name).first}&background=f97316&color=ffffff"

    photo.attach(io: URI.parse(url).open, filename: 'transporter.jpg')
  end

  def driving?
    !!driving
  end
end

# == Schema Information
#
# Table name: users
#
#  id                                  :bigint(8)        not null, primary key
#  email                               :string           not null
#  crypted_password                    :string
#  salt                                :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  remember_me_token                   :string
#  remember_me_token_expires_at        :datetime
#  reset_password_token                :string
#  reset_password_token_expires_at     :datetime
#  reset_password_email_sent_at        :datetime
#  access_count_to_reset_password_page :integer          default(0)
#  type                                :string
#  first_name                          :string
#  last_name                           :string
#  phone                               :string
#  role                                :integer          default("standard"), not null
#  availabilities                      :json             not null
#  archived_at                         :datetime
#  vehicle_id                          :bigint(8)
#  company_id                          :bigint(8)
#
# Indexes
#
#  index_users_on_company_id            (company_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_remember_me_token     (remember_me_token)
#  index_users_on_reset_password_token  (reset_password_token)
#  index_users_on_vehicle_id            (vehicle_id)
#
