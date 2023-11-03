class CustomerPolicy < ApplicationPolicy
  pre_check :admin_up?, except: :daily?

  relation_scope do |scope, search_query: nil, archived: false|
    scope = scope.includes(:address).with_attached_photo.with_all_rich_text.order(created_at: :desc)
    scope = scope.by_query(search_query) if search_query.present?
    scope = archived ? scope.archived : scope.available

    scope
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

  def archive?
    destroy?
  end

  def daily?
    true
  end
end
