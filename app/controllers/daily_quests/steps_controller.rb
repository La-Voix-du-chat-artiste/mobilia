module DailyQuests
  class StepsController < ApplicationController
    before_action :set_daily_quest
    before_action :set_step

    # @route GET /daily_quests/:daily_quest_id/steps/:id/edit (edit_daily_quest_step)
    def edit
      authorize! @step, context: { daily_quest: @daily_quest }
    end

    # @route PATCH /daily_quests/:daily_quest_id/steps/:id (daily_quest_step)
    # @route PUT /daily_quests/:daily_quest_id/steps/:id (daily_quest_step)
    def update
      authorize! @step, context: { daily_quest: @daily_quest }

      if @step.update(step_params)
        render partial: 'daily_quests/step', locals: { step: @step }
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # @route DELETE /daily_quests/:daily_quest_id/steps/:id (daily_quest_step)
    def destroy
      authorize! @step, context: { daily_quest: @daily_quest }

      @step.destroy

      respond_to do |format|
        notice = 'La mission a bien été supprimée'

        format.html { redirect_to daily_quests_path(date: @daily_quest.started_on), notice: notice }
        format.turbo_stream { flash.now[:notice] = notice }
      end
    end

    # @route POST /daily_quests/:daily_quest_id/steps/:id/optimize (optimize_daily_quest_step)
    def optimize
      authorize! @step, context: { daily_quest: @daily_quest }

      Optimizer.call(@step)

      redirect_to daily_quests_path(date: @daily_quest.started_on)
    end

    private

    def step_params
      params.require(:step).permit(:description)
    end

    def set_daily_quest
      @daily_quest = company.daily_quests.find(params[:daily_quest_id])
    end

    def set_step
      @step = @daily_quest.steps.find(params[:id])
    end
  end
end
