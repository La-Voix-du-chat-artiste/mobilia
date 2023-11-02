class User < ApplicationRecord
  EMAIL_REGEX = /\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+/

  enum role: { standard: 0, admin: 1, super_admin: 2 }, _default: :standard

  normalizes :email, with: -> { _1.strip.downcase }

  attr_accessor :remove_photo

  belongs_to :company

  authenticates_with_sorcery!

  has_one_attached :photo
  has_rich_text :details

  encrypts :first_name, :last_name, :phone
  encrypts :email, deterministic: true, downcase: true

  validates :email, presence: true,
                    format: { with: EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 },
                       presence: true,
                       confirmation: true,
                       if: :validate_password?
  validates :password_confirmation, presence: true, if: :validate_password?

  def full_name
    "#{first_name} #{last_name}"
  end

  def name
    full_name
  end

  private

  def validate_password?
    (new_record? && instance_of?(::User)) ||
      changes[:crypted_password] || reset_password_token_changed?
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
