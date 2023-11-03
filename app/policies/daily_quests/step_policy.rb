module DailyQuests
  class StepPolicy < ApplicationPolicy
    authorize :daily_quest

    pre_check :admin_up?
    pre_check :same_company?

    def edit?
      update?
    end

    def update?
      true
    end

    def destroy?
      true
    end

    def optimize?
      record.single? && allowed_to?(:optimize?, daily_quest)
    end

    private

    def same_company?
      deny! unless daily_quest.company == user.company
    end
  end
end
