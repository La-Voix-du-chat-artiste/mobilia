require 'rails_helper'

# Vehicles have no address, so their whole journey works without JavaScript:
# create, edit and delete through the real forms.
RSpec.describe 'Managing vehicles', type: :feature do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }

  before { sign_in_as(admin) }

  def fill_vehicle(name: 'Kangoo', plate: 'AB-123-CD')
    fill_in 'vehicle_name', with: name
    fill_in 'vehicle_number_plate', with: plate
    fill_in 'vehicle_max_regular_seats', with: '3'
    fill_in 'vehicle_max_wheelchair_seats', with: '1'
  end

  it 'creates a vehicle through the form' do
    visit new_vehicle_path
    fill_vehicle
    click_button 'Valider', exact: true

    expect(page).to have_content('Le véhicule a bien été créé')

    vehicle = company.vehicles.find_by!(number_plate: 'AB-123-CD')
    expect(vehicle.name).to eq('Kangoo')
    expect(page).to have_content('AB-123-CD')
  end

  it 'creates a vehicle and stays on the form when asked to' do
    visit new_vehicle_path
    fill_vehicle
    click_button 'Valider et créer un nouveau véhicule >>'

    expect(page).to have_content('Le véhicule a bien été créé')
    expect(page).to have_current_path(new_vehicle_path)
  end

  it 'reports a duplicate number plate inside the same company' do
    create(:vehicle, company: company, number_plate: 'AB-123-CD')

    visit new_vehicle_path
    fill_vehicle(name: 'Trafic', plate: 'AB-123-CD')
    click_button 'Valider', exact: true

    expect(page).to have_content('est déjà utilisé(e)')
    expect(company.vehicles.count).to eq(1)
  end

  it 'updates a vehicle' do
    vehicle = create(:vehicle, company: company, name: 'Kangoo')

    visit edit_vehicle_path(vehicle)
    fill_in 'vehicle_name', with: 'Trafic'
    click_button 'Valider', exact: true

    expect(page).to have_content('Le véhicule a bien été mis à jour')
    expect(vehicle.reload.name).to eq('Trafic')
  end

  it 'deletes a vehicle' do
    vehicle = create(:vehicle, company: company)

    visit vehicles_path
    click_button 'Supprimer'

    expect(page).to have_content('Le véhicule a bien été supprimé')
    expect(Vehicle.exists?(vehicle.id)).to be(false)
  end
end
