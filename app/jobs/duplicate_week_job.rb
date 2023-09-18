class DuplicateWeekJob < ApplicationJob
  def perform(daily_quest)
    DailyQuest.clone_week!(using: daily_quest)
  end
end
