class DailyQuestsController < ApplicationController
  MAX_HOUR = 18

  before_action :set_daily_quest, only: %i[
    show optimize duplicate_week reset
  ]

  # @route GET /daily_quests (daily_quests)
  def index
    authorize! DailyQuest

    # Planning redirect to next business day if current day is not
    unless calendar.business_day?(date)
      next_business_day = calendar.next_business_day(date)
      redirect_to daily_quests_path(date: next_business_day)
      return
    end

    # Planning redirect to tomorrow if todays missions are ended
    if params[:date].blank? && Time.current.hour >= MAX_HOUR
      next_business_day = calendar.next_business_day(Date.current)
      redirect_to daily_quests_path(date: next_business_day)
      return
    end

    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)

    transporters = authorized_scope(company.transporters.includes(:absences))
    @transporters = transporters.sort_by_courses_for(@daily_quest)
  end

  # @route GET /daily_quests/:id (daily_quest)
  def show
    authorize! @daily_quest

    @mission = if params[:currentMissionId].present?
      @daily_quest.missions.find(params[:currentMissionId])
    else
      @daily_quest.missions.first
    end
  end

  # @route POST /daily_quests/:id/optimize (optimize_daily_quest)
  def optimize
    authorize! @daily_quest

    steps = @daily_quest.missions.map(&:steps).flatten.select(&:single?).compact

    OptimizerJob.perform_later(steps.map(&:id))

    head :ok
  end

  # @route POST /daily_quests/:id/duplicate_week (duplicate_week_daily_quest)
  def duplicate_week
    authorize! @daily_quest

    DuplicateWeekJob.perform_later(@daily_quest)

    redirect_to daily_quests_path(date: @daily_quest.started_on), notice: 'La semaine est en cours de duplication. Veuillez patienter, cela peut prendre quelques minutes.'
  end

  # @route POST /daily_quests/:id/reset (reset_daily_quest)
  def reset
    authorize! @daily_quest

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
