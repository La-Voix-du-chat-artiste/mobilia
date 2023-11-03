class SettingPolicy < ApplicationPolicy
  pre_check :admin_up?

  def show?
    true
  end

  def edit?
    update?
  end

  def update?
    true
  end
end
