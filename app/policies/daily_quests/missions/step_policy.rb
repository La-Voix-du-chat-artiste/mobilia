module DailyQuests
  module Missions
    class StepPolicy < ApplicationPolicy
      authorize :daily_quest

      pre_check :admin_up?, except: :index?
      pre_check :same_company?

      def index?
        true
      end

      def update?
        !record.achieved?
      end

      private

      def same_company?
        deny! unless daily_quest.company == user.company
      end
    end
  end
end
