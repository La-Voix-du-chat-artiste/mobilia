class Transporter < User
  include Archivable
  include Optionable

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
  validates :phone, presence: true, if: :mandatory_phone?
  validates :phone,
            numericality: true,
            length: { is: 10 },
            allow_blank: -> { !mandatory_phone? }
  validates :vehicle, allow_blank: true, uniqueness: true

  def self.sort_by_courses_for(daily_quest)
    all.sort_by { |t| (t.step_ids & daily_quest.step_ids).count }
  end

  # `availabilities` is a json column that defaults to {} and the form only
  # writes the days it submits, so an entry can legitimately be missing. It used
  # to raise NoMethodError (undefined method 'to_sym' for nil) out of the
  # optimizer for any transporter created without availabilities. An undeclared
  # day is treated as no_work: a driver whose availability nobody has stated is
  # not auto-assigned.
  def periods_for?(my_date)
    day = my_date.to_date.strftime('%A').downcase
    period_name = availabilities[day].presence&.to_sym

    AvailabilitiesOption::PERIODS[period_name] || AvailabilitiesOption::PERIODS[:no_work]
  end

  def available_at?(started_at, arrival_at)
    periods = periods_for?(started_at)
    started_at.hour >= periods.first && arrival_at.hour <= periods.second
  end

  # `absences.present_today?` used to be called here, but present_today? was
  # defined with `def self.` on Absence: calling it on the association proxy
  # raised NoMethodError, so every planning screen that filters absent drivers
  # blew up.
  def off?(date = Date.current)
    absences.not_attending.covering(date).exists?
  end

  def no_vehicle?
    vehicle.nil?
  end

  def current_absence(date = Date.current)
    absences.not_attending.covering(date).last
  end

  def driving?
    !!driving
  end

  private

  def mandatory_phone?
    options.validate_phone_for_transporters?
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
#  role                                :integer          default(0), not null
#  availabilities                      :json             not null
#  archived_at                         :datetime
#  vehicle_id                          :bigint(8)
#  company_id                          :bigint(8)
#
# Indexes
#
#  index_users_on_company_id            (company_id)
#  index_users_on_email_and_company_id  (email,company_id) UNIQUE
#  index_users_on_remember_me_token     (remember_me_token)
#  index_users_on_reset_password_token  (reset_password_token)
#  index_users_on_vehicle_id            (vehicle_id)
#
