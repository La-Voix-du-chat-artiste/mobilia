class DailyQuestsController < ApplicationController
  MAX_HOUR = 18

  before_action :set_daily_quest, only: %i[
    show edit update destroy optimize duplicate_week reset
  ]

  # @route GET /daily_quests (daily_quests)
  def index
    # Planning redirect to tomorrow if todays missions are ended
    redirect_to daily_quests_path(date: Date.tomorrow) if params[:date].blank? && Time.current.hour >= MAX_HOUR

    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)
    @transporters = company.transporters.all.with_attached_photo.includes(:absences).sort_by_courses_for(@daily_quest)
  end

  # @route GET /daily_quests/:id (daily_quest)
  def show
    @mission = if params[:currentMissionId].present?
      @daily_quest.missions.find(params[:currentMissionId])
    else
      @daily_quest.missions.first
    end
  end

  # @route GET /daily_quests/new (new_daily_quest)
  def new
    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)

    redirect_to edit_daily_quest_path(@daily_quest)
  end

  # @route GET /daily_quests/:id/edit (edit_daily_quest)
  def edit
  end

  # @route PATCH /daily_quests/:id (daily_quest)
  # @route PUT /daily_quests/:id (daily_quest)
  def update
    respond_to do |format|
      if @daily_quest.update(daily_quest_params)
        format.html { redirect_to daily_quest_url(@daily_quest), notice: 'Le planning a bien été mis à jour' }
        format.json { render :show, status: :ok, location: @daily_quest }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @daily_quest.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route DELETE /daily_quests/:id (daily_quest)
  def destroy
    @daily_quest.destroy

    respond_to do |format|
      format.html { redirect_to daily_quests_url, notice: 'Le planning a bien été supprimé' }
      format.json { head :no_content }
    end
  end

  # @route POST /daily_quests/:id/optimize (optimize_daily_quest)
  def optimize
    steps = @daily_quest.missions.map(&:steps).flatten.select(&:single?).compact

    OptimizerJob.perform_later(steps)

    head :ok
  end

  # @route POST /daily_quests/:id/duplicate_week (duplicate_week_daily_quest)
  def duplicate_week
    DuplicateWeekJob.perform_later(@daily_quest)

    redirect_to daily_quests_path(date: @daily_quest.started_on), notice: 'La semaine est en cours de duplication. Veuillez patienter, cela peut prendre quelques minutes.'
  end

  # @route POST /daily_quests/:id/reset (reset_daily_quest)
  def reset
    ResetDailyQuest.call(@daily_quest)

    redirect_to daily_quests_path(date: @daily_quest.started_on), notice: 'Le planning du jour a bien été réinitialisé'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_daily_quest
    @daily_quest = company.daily_quests.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def daily_quest_params
    params.require(:daily_quest).permit(
      :started_on, :status,
      missions_attributes: %i[
        id drop_time drop_duration round_trip customer_id place_id _destroy
      ]
    )
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
