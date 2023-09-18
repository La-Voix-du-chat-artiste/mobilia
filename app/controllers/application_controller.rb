class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :require_login

  helper_method :company, :options

  private

  def company
    Current.company = current_user.company
    Current.company
  end

  def options
    company.setting.options
  end

  def not_authenticated
    redirect_to new_sessions_path,
                alert: 'Vous devez être authentifié pour accéder à cette page'
  end
end
