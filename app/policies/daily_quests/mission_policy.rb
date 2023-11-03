module DailyQuests
  class MissionPolicy < ApplicationPolicy
    authorize :daily_quest

    pre_check :admin_up?
    pre_check :same_company?

    def index?
      daily_quest.started_on >= Date.current
    end

    def new?
      create?
    end

    def create?
      true
    end

    def show?
      true
    end

    def edit?
      update?
    end

    def update?
      true
    end

    def destroy?
      true
    end

    private

    def same_company?
      deny! unless daily_quest.company == user.company
    end
  end
end
