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

  def periods_for?(my_date)
    day = my_date.to_date.strftime('%A').downcase
    period_name = availabilities[day].to_sym
    AvailabilitiesOption::PERIODS[period_name]
  end

  def available_at?(started_at, arrival_at)
    periods = periods_for?(started_at)
    Rails.logger.info [[started_at.hour, periods.first], [arrival_at.hour, periods.second]]
    started_at.hour >= periods.first && arrival_at.hour <= periods.second
  end

  def off?(date = Time.current)
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
#  role                                :integer          default("standard"), not null
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
