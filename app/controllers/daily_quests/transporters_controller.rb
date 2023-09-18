module DailyQuests
  class TransportersController < ApplicationController
    before_action :set_daily_quest
    before_action :set_transporter, only: :send_planning

    # @route POST /daily_quests/:daily_quest_id/transporters/send_all_plannings (send_all_plannings_daily_quest_transporters)
    def send_all_plannings
      transporters = company.daily_quests.with_attached_photo.includes(:absences)
      transporters = transporters.reject do |transporter|
        transporter.off?(@daily_quest.started_on)
      end

      transporters.each do |transporter|
        TransporterMailer
          .with(transporter: transporter, daily_quest: @daily_quest)
          .send_planning
          .deliver_later
      end

      respond_to do |format|
        notice = "Les plannings du jour sont en train d'être envoyés aux différents chauffeurs"

        format.html do
          redirect_to daily_quest_path(started_on: @daily_quest.started_on), notice: notice
        end
        format.turbo_stream { flash.now[:notice] = notice }
      end
    end

    # @route POST /daily_quests/:daily_quest_id/transporters/:id/send_planning (send_planning_daily_quest_transporter)
    def send_planning
      TransporterMailer
        .with(transporter: @transporter, daily_quest: @daily_quest)
        .send_planning
        .deliver_later

      respond_to do |format|
        notice = "Le planning a bien été envoyé par email à #{@transporter.full_name}"

        format.html do
          redirect_to daily_quest_path(started_on: @daily_quest.started_on), notice: notice
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
