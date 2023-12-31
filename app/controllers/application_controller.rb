class ApplicationController < ActionController::Base
  include Pagy::Backend

  before_action :require_login

  rescue_from ActionPolicy::Unauthorized, with: :unauthorized_access

  helper_method :company, :options, :calendar

  private

  def company
    Current.company = current_user.company
    Current.company
  end

  def options
    company.setting.options
  end

  def calendar
    @calendar ||= Business::Calendar.load_cached('targetfrance')
  end

  def not_authenticated
    redirect_to new_sessions_path,
                alert: 'Vous devez être authentifié pour accéder à cette page'
  end

  def unauthorized_access(e)
    policy_name = e.policy.class.to_s.underscore
    message = t "#{policy_name}.#{e.rule}", scope: 'action_policy', default: :default

    redirect_back_or_to root_path, alert: message
  end
end
