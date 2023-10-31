module DailyQuests
  module Missions
    class StepsController < ApplicationController
      before_action :set_daily_quest
      before_action :set_mission
      before_action :set_step, only: :update

      # @route GET /daily_quests/:daily_quest_id/missions/:mission_id/steps (daily_quest_mission_steps)
      def index
        authorize! Step, context: { daily_quest: @daily_quest }

        @steps = @mission.steps.all
      end

      # @route PATCH /daily_quests/:daily_quest_id/missions/:mission_id/steps/:id (daily_quest_mission_step)
      # @route PUT /daily_quests/:daily_quest_id/missions/:mission_id/steps/:id (daily_quest_mission_step)
      def update
        authorize! @step, context: { daily_quest: @daily_quest }

        return if @step.update(step_params)

        head :unprocessable_entity
      end

      private

      def set_daily_quest
        @daily_quest = company.daily_quests.find(params[:daily_quest_id])
      end

      def set_mission
        @mission = @daily_quest.missions.find(params[:mission_id])
      end

      def set_step
        @step = @daily_quest.steps.find(params[:id])
      end

      def step_params
        params.require(:step).permit(:transporter_id)
      end
    end
  end
end
