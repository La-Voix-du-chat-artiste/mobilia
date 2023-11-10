class DailyQuestPolicy < ApplicationPolicy
  pre_check :admin_up?, only: %i[destroy? optimize? duplicate_week? reset?]

  def index?
    true
  end

  def show?
    return false unless same_company?
    return false if record.missions.none?
    return true if admin? || super_admin?

    options.transporters_can_see_each_others?
  end

  def destroy?
    same_company? && record.missions.any?
  end

  def optimize?
    record.started_on >= Date.current && record.missions.any?
  end

  def duplicate_week?
    true
  end

  def reset?
    record.steps.any?(&:transporter)
  end
end
