class SettingPolicy < ApplicationPolicy
  pre_check :admin_up?

  def edit?
    update?
  end

  def update?
    true
  end
end
