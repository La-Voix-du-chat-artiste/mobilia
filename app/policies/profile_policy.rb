class ProfilePolicy < ApplicationPolicy
  def show?
    record == user
  end

  def edit?
    update?
  end

  def update?
    show?
  end
end
