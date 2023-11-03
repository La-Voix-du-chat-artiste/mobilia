class CompanyPolicy < ApplicationPolicy
  pre_check :admin_up?

  def new?
    create?
  end

  def create?
    true
  end

  def edit?
    update?
  end

  def update?
    user.company == record
  end
end
