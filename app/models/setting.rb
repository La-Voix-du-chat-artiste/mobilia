class Setting < ApplicationRecord
  belongs_to :company
  has_one :address, as: :addressable, dependent: :destroy

  attribute :options, SettingsOption.to_type
  accepts_nested_attributes_for :address, reject_if: :all_blank

  validates :options, store_model: { merge_errors: true }

  before_create :confirm_singularity!

  private

  def confirm_singularity!
    raise StandardError, 'There can be only one.' if Setting.find_by(id: company.id)
  end
end

# == Schema Information
#
# Table name: settings
#
#  id         :bigint(8)        not null, primary key
#  options    :json             not null
#  company_id :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_settings_on_company_id  (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
