require 'rails_helper'

# The journey a new customer takes: create a company, then the administrator
# account, and land on the dashboard already signed in.
RSpec.describe 'Onboarding a new company', type: :feature do
  def create_company(name: 'Transports Martin')
    visit new_companies_path
    fill_in 'company_name', with: name
    click_button 'Valider'
  end

  def fill_admin_account(email: 'camille@transports-martin.test', confirmation: 'password123')
    fill_in 'user_first_name', with: 'Camille'
    fill_in 'user_last_name', with: 'Martin'
    fill_in 'user_email', with: email
    fill_in 'user_password', with: 'password123'
    fill_in 'user_password_confirmation', with: confirmation
  end

  it 'creates the company, then the administrator account, and signs in' do
    create_company

    expect(page).to have_content("L'entreprise a bien été créée")

    fill_admin_account
    click_button 'Valider'

    expect(page).to have_content('Votre compte administrateur a bien été créé')

    company = Company.find_by!(name: 'Transports Martin')

    expect(company.users.count).to eq(1)
    expect(company.users.first).to be_admin
    expect(company.setting).to be_persisted
    expect(page).to have_content('Transports Martin')
  end

  it 'refuses a company without a name' do
    create_company(name: '')

    expect(page).to have_content('doit être rempli(e)')
    expect(Company.count).to eq(0)
  end

  it 'refuses mismatched passwords and creates no account' do
    create_company
    fill_admin_account(confirmation: 'password456')
    click_button 'Valider'

    expect(page).to have_content('ne concorde pas')
    expect(Company.find_by!(name: 'Transports Martin').users).to be_empty
  end

  it 'does not let a signed-in user create another company' do
    sign_in_as(create(:admin))

    visit new_companies_path

    expect(page).to have_current_path(root_path)
  end

  it 'takes an anonymous visitor to the company form before the account form' do
    visit new_user_path

    expect(page).to have_current_path(new_companies_path)
  end
end
