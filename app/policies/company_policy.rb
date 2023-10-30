class CompanyPolicy < ApplicationPolicy
  pre_check :allow_admins

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
    true
  end
end
