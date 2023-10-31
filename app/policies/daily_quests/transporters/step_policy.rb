module DailyQuests
  module Transporters
    class StepPolicy < ApplicationPolicy
      authorize :daily_quest

      pre_check :same_company?

      def index?
        return true if admin? || super_admin?

        record == user || options.transporters_can_see_each_others?
      end

      private

      def same_company?
        deny! unless daily_quest.company == user.company
      end
    end
  end
end
