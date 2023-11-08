class OptimizerJob < ApplicationJob
  include Rails.application.routes.url_helpers

  def perform(step_ids)
    @steps = Step.find(step_ids)
    daily_quest = @steps.first.mission.daily_quest

    total_steps = @steps.count

    @steps.each.with_index(1) do |step, index|
      last_one = total_steps == index
      percentage = (index / total_steps.to_f) * 100

      message = <<~MESSAGE.squish
        Les missions sont en cours d'assignation. Veuillez patienter, cela peut prendre quelques minutes. La page sera automatiquement rafraîchie une fois la tâche accomplie.

        <br />

        Placement de la mission <strong>#{index}/#{total_steps}</strong>, veuillez patienter...

        <div class="progress">
          <div class="progress-label" style="width: #{percentage.to_i}%">#{percentage.to_i}%</div>
        </div>
      MESSAGE

      if last_one
        message += <<~MESSAGE

          La page va être réactualisée dans quelques instants...
        MESSAGE
      end

      Step.broadcast_flash(
        :notice,
        "<div class=\"w-full\">#{message}</div>",
        stream: [daily_quest.company, :flash],
        disappear: false
      )

      Optimizer.call(step)
    end

    # This broadcast is only meant to reload the page once job is completed.
    Turbo::StreamsChannel.broadcast_append_to(
      [daily_quest.company, :page_reload],
      target: 'page_reload',
      partial: 'page_reload',
      locals: { url: daily_quests_path(date: daily_quest.started_on) }
    )
  end
end
