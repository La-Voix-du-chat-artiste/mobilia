require 'rails_helper'

RSpec.describe 'Signing in and out', type: :feature do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }

  it 'welcomes an anonymous visitor with the sign-in form' do
    visit root_path

    expect(page).to have_content('Connexion Mobilia')
  end

  it 'signs an administrator in and shows the dashboard' do
    sign_in_as(admin)

    expect(page).to have_content(company.name)
    expect(page).to have_link('Clients')
  end

  it 'refuses a wrong password and says so' do
    visit new_sessions_path
    fill_in 'session_email', with: admin.email
    fill_in 'session_password', with: 'not-the-password'
    click_button 'Se connecter'

    expect(page).to have_content('Erreur lors de la connexion')
  end

  it 'asks for the password reset when someone forgot it' do
    visit new_sessions_path
    click_link 'Mot de passe oublié ?'
    fill_in 'user_email', with: admin.email
    click_button 'Réinitialiser mon mot de passe'

    expect(page).to have_content('Les instructions pour réinitialiser votre mot de passe ont été envoyées.')
  end

  it 'does not expose the application to an anonymous visitor' do
    visit customers_path

    expect(page).to have_content('Vous devez être authentifié pour accéder à cette page')
    expect(page).to have_current_path(new_sessions_path)
  end
end
