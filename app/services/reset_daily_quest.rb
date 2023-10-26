class ResetDailyQuest < ApplicationService
  def initialize(daily_quest)
    @daily_quest = daily_quest
  end

  def call
    @daily_quest.steps.update_all(transporter_id: nil, status: :possible)
  end
end
