module DailyQuests
  module Transporters
    class StepsController < ApplicationController
      before_action :set_daily_quest
      before_action :set_transporter

      # @route GET /daily_quests/:daily_quest_id/transporters/:transporter_id/steps (daily_quest_transporter_steps)
      def index
        authorize! @transporter,
                   with: DailyQuests::Transporters::StepPolicy,
                   context: { daily_quest: @daily_quest }

        @steps = @daily_quest.steps.with_all_rich_text.where(transporter: @transporter)

        respond_to do |format|
          format.html
          format.pdf do
            name = "#{@daily_quest.started_on} - #{@transporter.full_name}".parameterize(separator: '_')

            render pdf: name
          end
        end
      end

      private

      def set_daily_quest
        @daily_quest = company.daily_quests.find(params[:daily_quest_id])
      end

      def set_transporter
        @transporter = company.transporters.find(params[:transporter_id])
      end
    end
  end
end
