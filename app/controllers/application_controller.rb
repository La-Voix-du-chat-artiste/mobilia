class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Around the action rather than before it, so the locale is restored when the
  # request ends instead of leaking into the next request served by the same
  # thread. Declared before require_login so that the "you must be signed in"
  # message is already in the visitor's language.
  around_action :use_selected_locale
  before_action :require_login

  rescue_from ActionPolicy::Unauthorized, with: :unauthorized_access

  helper_method :company, :options, :calendar

  private

  # The chosen language: `?locale=xx` first (that is what the switcher links to),
  # then whatever was chosen earlier in this session, then the default. An
  # unknown or unsupported value falls back to the default instead of raising, so
  # a stale link or a hand-edited query string cannot break a page.
  def use_selected_locale(&action)
    I18n.with_locale(selected_locale, &action)
  end

  def selected_locale
    requested = params[:locale].presence || session[:locale].presence
    locale = requested.to_s.to_sym
    locale = I18n.default_locale unless I18n.available_locales.include?(locale)
    # Only write to the session when the value actually changes: assigning the
    # same value on every request would rewrite the session cookie each time.
    session[:locale] = locale.to_s if session[:locale] != locale.to_s
    locale
  end

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
    redirect_to new_sessions_path, alert: t('flash.not_authenticated')
  end

  def unauthorized_access(e)
    policy_name = e.policy.class.to_s.underscore
    message = t "#{policy_name}.#{e.rule}", scope: 'action_policy', default: :default

    # `redirect_back_or_to` is now Rails' own method (see
    # config/initializers/sorcery.rb); sorcery's "URL the user was trying to
    # reach" variant is `redirect_to_before_login_path`.
    redirect_to_before_login_path root_path, alert: message
  end
end
