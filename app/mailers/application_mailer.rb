class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  # Renders the mail (and the PDF it attaches) in the language it was asked for.
  # Callers that enqueue a mail pass `locale: I18n.locale`, because a mail
  # rendered by a background job runs outside the request that asked for it and
  # would otherwise always come out in the default language. A mailer called
  # synchronously without a locale simply keeps the current one.
  around_action :switch_locale

  private

  def switch_locale(&action)
    I18n.with_locale(requested_locale, &action)
  end

  def requested_locale
    locale = params[:locale].to_s.to_sym
    I18n.available_locales.include?(locale) ? locale : I18n.locale
  end
end
