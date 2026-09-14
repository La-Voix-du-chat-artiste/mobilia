require 'rails_helper'

# Creating a *customer* through the UI is not covered here on purpose. The
# address field is a search-driven select (the Stimulus `address` controller
# queries the BAN API), so it cannot be filled without JavaScript. Everything
# else in the journey can, and is.
RSpec.describe 'Managing customers', type: :feature do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:customer) { create(:customer, company: company, first_name: 'Élodie', last_name: 'Nguyen') }

  before { sign_in_as(admin) }

  it 'lists the customers of the company' do
    visit customers_path

    expect(page).to have_content('Élodie Nguyen')
    expect(page).to have_link('Ajouter un client')
  end

  it 'updates a customer through the form' do
    visit edit_customer_path(customer)
    fill_in 'customer_first_name', with: 'Camille'
    click_button 'Valider', exact: true

    expect(page).to have_content('Le client a bien été mis à jour')
    expect(page).to have_content('Camille Nguyen')
    expect(customer.reload.first_name).to eq('Camille')
  end

  it 'shows the validation errors instead of saving' do
    visit edit_customer_path(customer)
    fill_in 'customer_first_name', with: ''
    click_button 'Valider', exact: true

    expect(page).to have_content('doit être rempli(e)')
    expect(customer.reload.first_name).to eq('Élodie')
  end

  it 'archives a customer and restores it' do
    visit customers_path
    within("#customer_#{customer.id}") { click_button 'Archiver' }

    expect(page).to have_content('Le client a bien été archivé')
    expect(customer.reload).to be_archived

    visit customers_path(archived: true)
    within("#customer_#{customer.id}") { click_button 'Désarchiver' }

    expect(page).to have_content('Le client a bien été désarchivé')
    expect(customer.reload).to be_available
  end

  it 'deletes a customer' do
    visit customers_path
    within("#customer_#{customer.id}") { click_button 'Supprimer' }

    expect(page).to have_content('Le client a bien été supprimé')
    expect(Customer.exists?(customer.id)).to be(false)
  end

  it 'filters the list by query' do
    other = create(:customer, company: company, first_name: 'Zoe', last_name: 'Zephyr')

    visit customers_path(search: { query: 'Nguyen' })

    expect(page).to have_content('Élodie Nguyen')
    expect(page).not_to have_content(other.full_name)
  end

  it 'only shows the archived customers in the archived view' do
    archived = create(:customer, company: company, first_name: 'Parti', last_name: 'Ancien')
    archived.archive!

    visit customers_path(archived: true)

    expect(page).to have_content('Parti Ancien')
    expect(page).not_to have_content('Élodie Nguyen')
  end
end
