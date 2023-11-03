module Transporters
  class AbsencePolicy < ApplicationPolicy
    authorize :transporter

    pre_check :same_company?

    def new?
      create?
    end

    def create?
      admin? || super_admin? || transporter == user
    end

    def edit?
      update?
    end

    def update?
      create?
    end

    def destroy?
      update?
    end

    private

    def same_company?
      deny! unless transporter.company == user.company
    end
  end
end
