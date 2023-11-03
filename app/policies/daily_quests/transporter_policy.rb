module DailyQuests
  class TransporterPolicy < ApplicationPolicy
    authorize :daily_quest

    pre_check :admin_up?, only: :send_all_plannings?
    pre_check :same_company?

    def send_all_plannings?
      daily_quest.steps.any?(&:transporter)
    end

    def send_planning?
      admin? || super_admin? || record == user
    end

    private

    def same_company?
      deny! unless daily_quest.company == user.company
    end
  end
end
