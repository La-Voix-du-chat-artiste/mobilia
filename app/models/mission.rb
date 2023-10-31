class Mission < ApplicationRecord
  attr_accessor :drop_duration_hours, :drop_duration_minutes

  belongs_to :daily_quest
  belongs_to :customer
  belongs_to :place
  has_many :steps, dependent: :destroy

  validates :drop_time, presence: true
  validates :drop_duration_hours,
            presence: true,
            if: -> { round_trip? && drop_duration_minutes.blank? }
  validates :drop_duration_minutes,
            presence: true,
            if: -> { round_trip? && drop_duration_hours.blank? }
  validates :drop_duration_hours,
            allow_blank: true,
            numericality: { greater_than_or_equal_to: 0, less_than: 24 }
  validates :drop_duration_minutes,
            allow_blank: true,
            numericality: { greater_than_or_equal_to: 0, less_than: 60 }

  default_scope -> { order(:drop_time) }

  scope :by_position, -> { order(:position) }

  before_validation :assign_drop_duration
  after_create :generate_steps
  after_update :regenerate_steps

  def drop_datetime
    hour = drop_time.hour.hour
    minute = drop_time.min.minute
    daily_quest.started_on + hour + minute
  end

  private

  def assign_drop_duration
    self.drop_duration = (drop_duration_hours.to_i * 60) + drop_duration_minutes.to_i
  end

  def generate_steps
    GenerateSteps.call(daily_quest, self)
  end

  def regenerate_steps
    steps.destroy_all
    generate_steps
  end
end

# == Schema Information
#
# Table name: missions
#
#  id             :bigint(8)        not null, primary key
#  drop_time      :time
#  drop_duration  :integer
#  position       :integer          default(1), not null
#  customer_id    :bigint(8)        not null
#  place_id       :bigint(8)        not null
#  daily_quest_id :bigint(8)        not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  round_trip     :boolean          default(TRUE), not null
#
# Indexes
#
#  index_missions_on_customer_id     (customer_id)
#  index_missions_on_daily_quest_id  (daily_quest_id)
#  index_missions_on_place_id        (place_id)
#
