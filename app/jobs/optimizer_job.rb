class OptimizerJob < ApplicationJob
  include Rails.application.routes.url_helpers

  # The job broadcasts its progress into the browser, so it has to speak the
  # language of the person who asked for the optimisation. A job runs outside
  # that request, so the locale travels with the arguments instead.
  def perform(step_ids, locale: I18n.default_locale.to_s)
    previous_locale = I18n.locale
    I18n.locale = locale.to_s.to_sym if I18n.available_locales.include?(locale.to_s.to_sym)

    @steps = Step.find(step_ids)

    # `Step.find([])` returns [] rather than raising, and @steps.first was then
    # nil: the job died with "undefined method 'mission' for nil" and reported it
    # to every connected tenant.
    return if @steps.empty?

    @daily_quest = @steps.first.mission.daily_quest

    total_steps = @steps.count

    @steps.each.with_index(1) do |step, index|
      last_one = total_steps == index
      percentage = (index / total_steps.to_f) * 100

      message = <<~MESSAGE.squish
        #{I18n.t('flash.optimizer.running')}

        <br />

        #{I18n.t('flash.optimizer.step_progress_html', index: index, total: total_steps)}

        <div class="progress">
          <div class="progress-label" style="width: #{percentage.to_i}%">#{percentage.to_i}%</div>
        </div>
      MESSAGE

      if last_one
        message += <<~MESSAGE

          #{I18n.t('flash.optimizer.reloading')}
        MESSAGE
      end

      Step.broadcast_flash(
        :notice,
        "<div class=\"w-full\">#{message}</div>",
        stream: [@daily_quest.company, :flash],
        disappear: false
      )

      Optimizer.call(step)
    end

    # This broadcast is only meant to reload the page once job is completed.
    Turbo::StreamsChannel.broadcast_append_to(
      [@daily_quest.company, :page_reload],
      target: 'page_reload',
      partial: 'page_reload',
      locals: { url: daily_quests_path(date: @daily_quest.started_on) }
    )
  ensure
    # Job threads are reused, so the locale has to go back to what it was.
    I18n.locale = previous_locale
  end

  private

  def error_stream
    @daily_quest ? [@daily_quest.company, :flash] : :flash
  end
end
