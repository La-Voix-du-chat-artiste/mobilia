module DailyQuests
  class TransportersController < ApplicationController
    before_action :set_daily_quest
    before_action :set_transporter, only: :send_planning

    # @route POST /daily_quests/:daily_quest_id/transporters/send_all_plannings (send_all_plannings_daily_quest_transporters)
    def send_all_plannings
      authorize! Transporter, context: { daily_quest: @daily_quest }

      # This used to read `company.daily_quests.with_attached_photo`, which
      # raised NoMethodError: DailyQuest has no photo attachment. The intent is
      # obviously the company's transporters.
      transporters = company.transporters.with_attached_photo.includes(:absences)
      transporters = transporters.reject do |transporter|
        transporter.off?(@daily_quest.started_on)
      end

      transporters.each do |transporter|
        TransporterMailer
          .with(transporter: transporter, daily_quest: @daily_quest, locale: I18n.locale)
          .send_planning
          .deliver_later
      end

      respond_to do |format|
        notice = t('flash.daily_quests.transporters.send_all_plannings')

        format.html do
          # `daily_quest_path` is the show route and requires :id. This action is
          # reached through the nested /daily_quests/:daily_quest_id/... route, so
          # there is no params[:id] for the helper to fall back on and it raised
          # UrlGenerationError. Every other redirect in the planning flow goes
          # back to the board, which is also where the button lives.
          redirect_to daily_quests_path(date: @daily_quest.started_on), notice: notice
        end
        format.turbo_stream { flash.now[:notice] = notice }
      end
    end

    # @route POST /daily_quests/:daily_quest_id/transporters/:id/send_planning (send_planning_daily_quest_transporter)
    def send_planning
      authorize! @transporter, context: { daily_quest: @daily_quest }

      TransporterMailer
        .with(transporter: @transporter, daily_quest: @daily_quest, locale: I18n.locale)
        .send_planning
        .deliver_later

      respond_to do |format|
        notice = t('flash.daily_quests.transporters.send_planning', name: @transporter.full_name)

        format.html do
          # See send_all_plannings: daily_quest_path needs :id.
          redirect_to daily_quests_path(date: @daily_quest.started_on), notice: notice
        end
        format.turbo_stream { flash.now[:notice] = notice }
      end
    end

    private

    def set_daily_quest
      @daily_quest = company.daily_quests.find(params[:daily_quest_id])
    end

    def set_transporter
      @transporter = company.transporters.find(params[:id])
    end
  end
end
