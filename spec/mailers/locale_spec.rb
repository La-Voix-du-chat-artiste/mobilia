require 'rails_helper'

# A mail is rendered by a background job, outside the request that asked for it,
# so the language travels with the mailer parameters (see ApplicationMailer and
# DailyQuests::TransportersController). This is the only place that exercises the
# plumbing, and the only place that would notice a mail template still hardcoding
# French.
RSpec.describe 'Mailer locales' do
  let(:company) { create(:company) }
  let!(:user) { create(:admin, company: company) }

  # The mails are multipart, so their bodies are base64 encoded: decode before
  # looking for a translated sentence.
  def body_of(mail)
    parts = mail.body.parts
    parts.any? ? parts.map(&:decoded).join : mail.body.decoded
  end

  before do
    # update_columns, not update!: changing reset_password_token is what makes
    # User require a password, which this record does not need for a mail spec.
    user.update_columns(reset_password_token: 'a-reset-token', reset_password_token_expires_at: 1.hour.from_now)
  end

  describe UserMailer do
    it 'writes the mail in the language it is given' do
      mail = UserMailer.with(locale: :en).reset_password_email(user)

      expect(mail.subject).to eq('Reset your password')
      expect(body_of(mail)).to include('Hello')
    end

    it 'writes it in Chinese when asked for Chinese' do
      mail = UserMailer.with(locale: :zh).reset_password_email(user)

      expect(mail.subject).to eq('重置您的密码')
      expect(body_of(mail)).to include('您好')
    end

    it 'keeps the language of the request when none is given' do
      I18n.with_locale(:zh) do
        expect(UserMailer.reset_password_email(user).subject).to eq('重置您的密码')
      end
    end

    it 'falls back to the default language for an unsupported one' do
      mail = UserMailer.with(locale: :klingon).reset_password_email(user)

      expect(mail.subject).to eq('Réinitialisation de votre mot de passe')
    end
  end
end
