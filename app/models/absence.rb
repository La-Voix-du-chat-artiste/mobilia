class Absence < ApplicationRecord
  # Rails 8 requires the positional form: `enum reason: {...}` now raises
  # ArgumentError, and `_default` / `_prefix` are no longer valid options.
  enum :reason, { unspecified: 0, holidays: 1, disease: 2, other_company: 3, attending: 4 }

  belongs_to :transporter

  humanize :reason, enum: true

  validates :started_on, presence: true
  validates :ended_on, presence: true

  # Absences covering the given day. Also used by Transporter#off? and by the
  # planning screens, which previously each re-wrote the SQL string.
  scope :covering, ->(date) { where(started_on: ..date.to_date).where(ended_on: date.to_date..) }

  after_create :unassign_steps, unless: :attending?

  # An "attending" absence means the transporter is actually present, so it must
  # not make them unavailable.
  def self.unavailable_on?(date = Date.current)
    not_attending.covering(date).exists?
  end

  def unassign_steps
    # Resetting the status matters: a step that lost its transporter is
    # unassigned again, not in conflict.
    transporter.steps
               .where(started_at: started_on.beginning_of_day..ended_on.end_of_day)
               .update_all(transporter_id: nil, status: Step.statuses[:possible])
  end
end

# == Schema Information
#
# Table name: absences
#
#  id             :bigint(8)        not null, primary key
#  started_on     :date
#  ended_on       :date
#  reason         :integer          default(0), not null
#  transporter_id :bigint(8)        not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_absences_on_transporter_id  (transporter_id)
#
