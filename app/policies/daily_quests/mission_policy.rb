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
      company.customers.enabled.any? && company.places.enabled.any? &&
        company.transporters.any? && company.vehicles.enabled.normal.any?
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
      deny! unless company == user.company
    end

    def company
      daily_quest.company
    end
  end
end
