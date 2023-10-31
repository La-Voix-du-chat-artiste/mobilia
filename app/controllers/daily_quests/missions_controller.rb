module DailyQuests
  class MissionsController < ApplicationController
    before_action :set_daily_quest, except: :index
    before_action :set_mission, only: %i[show edit update destroy]

    # @route GET /daily_quests/:daily_quest_id/missions (daily_quest_missions)
    def index
      if params[:date].present?
        set_daily_quest_by_date
      else
        set_daily_quest
      end

      @missions = @daily_quest.missions
    end

    # @route GET /daily_quests/:daily_quest_id/missions/new (new_daily_quest_mission)
    def new
      @mission = @daily_quest.missions.new
    end

    # @route POST /daily_quests/:daily_quest_id/missions (daily_quest_missions)
    def create
      @mission = @daily_quest.missions.new(mission_params)

      respond_to do |format|
        if @mission.save
          notice = 'La mission a bien été créé.'

          format.html { redirect_to daily_quest_missions_path(@daily_quest), notice: notice }
          format.turbo_stream { flash.now[:notice] = notice }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    # @route GET /daily_quests/:daily_quest_id/missions/:id (daily_quest_mission)
    def show
    end

    # @route GET /daily_quests/:daily_quest_id/missions/:id/edit (edit_daily_quest_mission)
    def edit
    end

    # @route PATCH /daily_quests/:daily_quest_id/missions/:id (daily_quest_mission)
    # @route PUT /daily_quests/:daily_quest_id/missions/:id (daily_quest_mission)
    def update
      if @mission.update(mission_params)
        redirect_to daily_quest_mission_path(@daily_quest, @mission), notice: 'La mission a bien été mise à jour.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # @route DELETE /daily_quests/:daily_quest_id/missions/:id (daily_quest_mission)
    def destroy
      @mission.destroy

      respond_to do |format|
        notice = 'La mission a bien été supprimée'

        format.html { redirect_to daily_quest_missions_path(date: @daily_quest.started_on), notice: notice }
        format.turbo_stream { flash.now[:notice] = notice }
      end
    end

    private

    def mission_params
      params.require(:mission).permit(
        :drop_time, :round_trip, :drop_duration_hours,
        :drop_duration_minutes, :customer_id, :place_id
      )
    end

    def set_daily_quest
      @daily_quest = company.daily_quests.find(params[:daily_quest_id])
    end

    def set_daily_quest_by_date
      @daily_quest = company.daily_quests.find_or_create_by(started_on: date)

      redirect_to daily_quest_missions_path(@daily_quest)
    end

    def set_mission
      @mission = @daily_quest.missions.find(params[:id])
    end

    def date
      if params[:date].present?
        begin
          Date.parse(params[:date])
        rescue StandardError
          Date.current
        end
      else
        Date.current
      end
    end
  end
end
