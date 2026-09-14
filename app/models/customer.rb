class Customer < ApplicationRecord
  include Archivable
  include Optionable
  include PhotoAssignable

  # A 2-3 character TLD cap rejected valid addresses such as .info, .museum or
  # a +tag in the local part. URI::MailTo::EMAIL_REGEXP is the standard Rails
  # compromise between permissiveness and typo catching.
  EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  enum :kind, { walker: 0, wheelchair: 1, wheelchair_auto: 2 }, default: :wheelchair

  normalizes :email, with: -> { it.strip.downcase }

  belongs_to :company
  belongs_to :favorite_trip_transporter, class_name: 'Transporter', optional: true
  belongs_to :favorite_trip_back_transporter, class_name: 'Transporter', optional: true
  has_one :address, as: :addressable, dependent: :destroy
  has_many :missions, dependent: :destroy

  accepts_nested_attributes_for :address, reject_if: :all_blank

  has_one_attached :photo
  has_rich_text :details

  humanize :kind, enum: true

  # encrypts :first_name, :last_name, :phone, :email, deterministic: true

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true, if: :mandatory_phone?
  validates :phone,
            numericality: true,
            length: { is: 10 },
            allow_blank: -> { !mandatory_phone? }
  validates :email, allow_blank: true, format: { with: EMAIL_REGEX }
  validates :address, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :by_query, lambda { |query|
    joins(:address)
      .where(arel_table[:first_name].matches("%#{query}%"))
      .or(where(arel_table[:last_name].matches("%#{query}%")))
      .or(where(arel_table[:phone].matches("%#{query}%")))
      .or(where('"addresses"."label" ILIKE ?', "%#{query}%"))
  }

  after_create :assign_photo

  def full_name
    "#{first_name} #{last_name}"
  end

  def name
    full_name
  end

  def details?
    details.to_s.strip.present?
  end

  def formatted_phone_number
    phone.to_s.chars.each_slice(2).map(&:join).join(' ')
  end

  def in_wheelchair?
    wheelchair? || wheelchair_auto?
  end

  private

  def assign_photo
    attach_generated_photo(
      self.class.avatar_url(
        "#{I18n.transliterate(first_name).first} #{I18n.transliterate(last_name).first}",
        background: '22c55e'
      ),
      'customer.jpg'
    )
  end

  def mandatory_phone?
    options.validate_phone_for_customers?
  end
end

# == Schema Information
#
# Table name: customers
#
#  id                                :bigint(8)        not null, primary key
#  first_name                        :string
#  last_name                         :string
#  phone                             :string
#  email                             :string
#  kind                              :integer          default(0), not null
#  enabled                           :boolean          default(TRUE), not null
#  archived_at                       :datetime
#  favorite_trip_transporter_id      :bigint(8)
#  favorite_trip_back_transporter_id :bigint(8)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  company_id                        :bigint(8)
#
# Indexes
#
#  index_customers_on_company_id                         (company_id)
#  index_customers_on_favorite_trip_back_transporter_id  (favorite_trip_back_transporter_id)
#  index_customers_on_favorite_trip_transporter_id       (favorite_trip_transporter_id)
#
