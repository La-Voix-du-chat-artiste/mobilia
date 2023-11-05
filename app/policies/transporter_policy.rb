class TransporterPolicy < ApplicationPolicy
  pre_check :admin_up?, only: %i[new? create? destroy?]

  relation_scope do |scope|
    query = scope.includes(:address, vehicle: [:company, photo_attachment: :blob]).with_attached_photo.with_all_rich_text

    next query if super_admin? || admin? || options.transporters_can_see_each_others?

    query.where(id: user.id)
  end

  def index?
    true
  end

  def new?
    create?
  end

  def create?
    true
  end

  def show?
    return false unless same_company?
    return true if admin? || super_admin?

    record == user || options.transporters_can_see_each_others?
  end

  def edit?
    update?
  end

  def update?
    (admin? || super_admin?) && same_company?
  end

  def destroy?
    same_company?
  end

  def daily?
    true
  end
end
