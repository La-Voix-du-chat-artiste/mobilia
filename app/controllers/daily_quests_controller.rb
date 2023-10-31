class DailyQuestsController < ApplicationController
  MAX_HOUR = 18

  before_action :set_daily_quest, only: %i[
    show optimize duplicate_week reset
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

  # @route POST /daily_quests/:id/optimize (optimize_daily_quest)
  def optimize
    steps = @daily_quest.missions.map(&:steps).flatten.select(&:single?).compact

    OptimizerJob.perform_later(steps.map(&:id))

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
