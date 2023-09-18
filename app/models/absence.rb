class Absence < ApplicationRecord
  enum reason: { unspecified: 0, holidays: 1, disease: 2, other_company: 3, attending: 4 }

  belongs_to :transporter

  humanize :reason, enum: true

  validates :started_on, presence: true
  validates :ended_on, presence: true

  after_create :unassign_steps, unless: :attending?

  def self.present_today?(date = Date.current)
    found = where('started_on <= :date and ended_on >= :date', date: date)
    Rails.logger.info "  ***** #{date} found #{found.all.inspect} ******  "

    found.any? && found.none? { |f| f.reason == 'attending' }
  end

  def unassign_steps
    steps = transporter.steps.where(started_at: started_on..ended_on)
    steps.update_all(transporter_id: nil)
  end

  # def off_today?(time = Time.current)
  #   time.between?(started_at, ended_at)
  # end

  # def present_today?(time = Time.current)
  #   time.between?(started_at, ended_at)
  # end
end

# == Schema Information
#
# Table name: absences
#
#  id             :bigint(8)        not null, primary key
#  started_on     :date
#  ended_on       :date
#  reason         :integer          default("unspecified"), not null
#  transporter_id :bigint(8)        not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_absences_on_transporter_id  (transporter_id)
#
