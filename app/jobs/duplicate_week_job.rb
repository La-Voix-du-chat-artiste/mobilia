class DuplicateWeekJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(daily_quest)
    DailyQuest.clone_week!(using: daily_quest)

    # This broadcast is only meant to reload the page once job is completed.
    Turbo::StreamsChannel.broadcast_append_to(
      [daily_quest.company, :page_reload],
      target: 'page_reload',
      partial: 'page_reload',
      locals: { url: daily_quests_path(date: daily_quest.started_on + 7.days) }
    )
  end
end
