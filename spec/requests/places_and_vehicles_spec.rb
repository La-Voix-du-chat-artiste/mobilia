require 'rails_helper'

RSpec.describe 'Places', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:place) { create(:place, company: company, name: 'Clinique Saint-Jean') }

  before { sign_in(admin) }

  def place_params(overrides = {})
    { name: 'Hôpital Nord', address_attributes: { label: '1 place Bellecour, 69002 Lyon' } }
      .merge(overrides)
  end

  it 'renders the list' do
    get places_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Clinique Saint-Jean')
  end

  it 'filters by query across name and address' do
    other = create(:place, company: company, name: 'Zoo de Lyon')

    get places_path, params: { search: { query: 'Clinique' } }

    expect(response.body).to include('Clinique Saint-Jean')
    expect(response.body).not_to include(other.name)
  end

  it 'answers the map JSON' do
    get places_path, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.pluck('name')).to include('Clinique Saint-Jean')
  end

  it 'creates a place' do
    expect { post places_path, params: { place: place_params } }.to change(Place, :count).by(1)

    expect(response).to redirect_to(place_path(Place.last))
    expect(Place.last.company).to eq(company)
  end

  it 're-renders the form when the name is missing' do
    expect { post places_path, params: { place: place_params(name: '') } }.not_to change(Place, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('doit être rempli(e)')
  end

  it 'returns to the blank form in save-and-create-new mode' do
    post places_path, params: { place: place_params, mode: 'save_and_create_new' }

    expect(response).to redirect_to(new_place_path)
  end

  it 'updates a place' do
    patch place_path(place), params: { place: { name: 'Clinique Sud' } }

    expect(response).to redirect_to(place_path(place))
    expect(place.reload.name).to eq('Clinique Sud')
  end

  it 'destroys a place' do
    expect { delete place_path(place) }.to change(Place, :count).by(-1)

    expect(response).to redirect_to(places_path)
  end

  it 'answers 404 for another company\'s place' do
    get place_path(create(:place, company: create(:company)))

    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe 'Vehicles', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:vehicle) { create(:vehicle, company: company, number_plate: 'AB-123-CD') }

  before { sign_in(admin) }

  def vehicle_params(overrides = {})
    { name: 'Kangoo', number_plate: 'EF-456-GH', max_regular_seats: 3, max_wheelchair_seats: 1 }
      .merge(overrides)
  end

  it 'renders the list' do
    get vehicles_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('AB-123-CD')
  end

  it 'creates a vehicle' do
    expect { post vehicles_path, params: { vehicle: vehicle_params } }.to change(Vehicle, :count).by(1)

    expect(response).to redirect_to(vehicle_path(Vehicle.last))
    expect(Vehicle.last.company).to eq(company)
  end

  it 're-renders the form when the plate is already used in the company' do
    expect { post vehicles_path, params: { vehicle: vehicle_params(number_plate: 'AB-123-CD') } }
      .not_to change(Vehicle, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('est déjà utilisé(e)')
  end

  it 'accepts a plate that another company already uses' do
    create(:vehicle, company: create(:company), number_plate: 'EF-456-GH')

    expect { post vehicles_path, params: { vehicle: vehicle_params } }.to change(Vehicle, :count).by(1)
  end

  it 'updates a vehicle' do
    patch vehicle_path(vehicle), params: { vehicle: { name: 'Trafic' } }

    expect(response).to redirect_to(vehicle_path(vehicle))
    expect(vehicle.reload.name).to eq('Trafic')
  end

  it 'unassigns the driver when the vehicle breaks down' do
    transporter = create(:transporter, company: company, vehicle: vehicle)

    patch vehicle_path(vehicle), params: { vehicle: { status: 'breakdown' } }

    expect(transporter.reload.vehicle_id).to be_nil
  end

  it 'destroys a vehicle' do
    expect { delete vehicle_path(vehicle) }.to change(Vehicle, :count).by(-1)

    expect(response).to redirect_to(vehicles_path)
  end

  it 'answers 404 for another company\'s vehicle' do
    get vehicle_path(create(:vehicle, company: create(:company)))

    expect(response).to have_http_status(:not_found)
  end
end
