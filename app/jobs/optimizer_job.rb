class OptimizerJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(step_ids)
    @steps = Step.find(step_ids)
    daily_quest = @steps.first.mission.daily_quest

    total_steps = @steps.count

    @steps.each_with_index do |step, index|
      last_one = total_steps == index + 1

      message = <<~MESSAGE
        Les missions sont en cours d'assignation. Veuillez patienter, cela peut prendre quelques minutes. La page sera automatiquement rafraîchie une fois la tâche accomplie.

        Placement de la mission <strong>#{index + 1}/#{total_steps}</strong>, veuillez patienter...
      MESSAGE

      if last_one
        message += <<~MESSAGE
          La page va être réactualisée dans quelques instants...
        MESSAGE
      end

      Turbo::StreamsChannel.broadcast_update_to(
        :flash,
        target: 'flash',
        partial: 'flash',
        locals: {
          flash_type: 'notice',
          message: message
        }
      )

      Optimizer.call(step)
    end

    # This broadcast is only meant to reload the page once job is completed.
    Turbo::StreamsChannel.broadcast_append_to(
      :page_reload,
      target: 'page_reload',
      partial: 'page_reload',
      locals: { url: daily_quests_path(date: daily_quest.started_on) }
    )
  end
end
