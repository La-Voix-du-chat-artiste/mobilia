class VehiclePolicy < ApplicationPolicy
  pre_check :admin_up?

  relation_scope do |scope|
    scope.with_all_rich_text.with_attached_photo.includes(transporter: [photo_attachment: :blob])
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
    same_company?
  end

  def edit?
    update?
  end

  def update?
    same_company?
  end

  def destroy?
    same_company?
  end
end
