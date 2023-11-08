class DailyQuest < ApplicationRecord
  WAITING_TIME = 30.minutes # time before hiding steps

  enum status: { not_started: 0, pending: 1, ended: 2 }, _default: :not_started

  belongs_to :company
  has_many :missions, dependent: :destroy
  has_many :steps, through: :missions

  validates :started_on, presence: true

  accepts_nested_attributes_for :missions, reject_if: :all_blank, allow_destroy: true

  def self.clone_week!(using:)
    my_week = using.company
                   .daily_quests
                   .joins(:missions)
                   .where(started_on: (using.started_on.beginning_of_week)..(using.started_on.end_of_week))

    my_week.each do |daily|
      started_on = daily.started_on.in(1.week)
      my_daily_quest = daily.company.daily_quests.find_or_create_by(
        started_on: started_on
      )
      my_daily_quest.save!

      Rails.logger.debug my_daily_quest.inspect

      my_daily_quest.missions.delete_all
      daily.missions.each do |mission|
        my_mission = mission.dup
        my_mission.drop_duration_hours = mission.drop_duration / 60
        my_mission.drop_duration_minutes = mission.drop_duration % 60
        my_mission.daily_quest_id = my_daily_quest.id
        my_mission.save!
        Rails.logger.debug my_mission.inspect
      end
    end
  end

  def title
    I18n.l(started_on)
  end

  def recompute_missions_position
    missions.order(drop_time: :asc).each_with_index do |mission, index|
      mission.update_column :position, index + 1
    end
  end

  # def recompute_steps_position
  # missions.map(&:steps).flatten
  # end
end

# == Schema Information
#
# Table name: daily_quests
#
#  id         :bigint(8)        not null, primary key
#  started_on :date
#  status     :integer          default("not_started"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint(8)
#
# Indexes
#
#  index_daily_quests_on_company_id  (company_id)
#
