require 'rails_helper'

RSpec.describe 'Transporters', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:transporter) { create(:transporter, company: company, first_name: 'Jean', last_name: 'Dupont') }

  before { sign_in(admin) }

  def transporter_params(overrides = {})
    {
      first_name: 'Marie',
      last_name: 'Durand',
      email: 'marie@example.test',
      password: 'password123',
      password_confirmation: 'password123',
      address_attributes: { label: '1 place Bellecour, 69002 Lyon' },
      availabilities: { monday: 'all_day', tuesday: 'morning' }
    }.merge(overrides)
  end

  describe 'GET /transporters' do
    it 'renders the list' do
      get transporters_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Jean Dupont')
    end

    it 'answers the map JSON' do
      get transporters_path, as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /transporters' do
    it 'creates a driver with a password and an address' do
      expect { post transporters_path, params: { transporter: transporter_params } }
        .to change(Transporter, :count).by(1)

      created = Transporter.find_by!(email: 'marie@example.test')
      expect(created.company).to eq(company)
      expect(Transporter.authenticate('marie@example.test', 'password123')).to eq(created)
      expect(response).to redirect_to(transporter_path(created))
    end

    it 're-renders the form when the password is missing' do
      params = transporter_params(password: nil, password_confirmation: nil)

      expect { post transporters_path, params: { transporter: params } }
        .not_to change(Transporter, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 're-renders the form when the email is already used in the company' do
      params = transporter_params(email: transporter.email)

      expect { post transporters_path, params: { transporter: params } }
        .not_to change(Transporter, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'PATCH /transporters/:id' do
    it 'updates the driver' do
      patch transporter_path(transporter), params: { transporter: { first_name: 'Jeanne' } }

      expect(response).to redirect_to(transporter_path(transporter))
      expect(transporter.reload.first_name).to eq('Jeanne')
    end
  end

  describe 'DELETE /transporters/:id' do
    it 'removes the driver' do
      expect { delete transporter_path(transporter) }.to change(Transporter, :count).by(-1)

      expect(response).to redirect_to(transporters_path)
    end
  end

  describe 'GET /transporters/:id' do
    it 'paginates the absences' do
      create(:absence, transporter: transporter, reason: :holidays)

      get transporter_path(transporter)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /transporters/daily' do
    it 'answers the map JSON' do
      get daily_transporters_path, as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  it 'answers 404 for another company\'s driver' do
    get transporter_path(create(:transporter, company: create(:company)))

    expect(response).to have_http_status(:not_found)
  end
end

RSpec.describe 'Absences', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:transporter) { create(:transporter, company: company) }

  before { sign_in(admin) }

  it 'renders the new form' do
    get new_transporter_absence_path(transporter)

    expect(response).to have_http_status(:ok)
  end

  it 'records an absence' do
    expect do
      post transporter_absences_path(transporter),
           params: { absence: { started_on: Date.current, ended_on: Date.current + 2, reason: 'holidays' } }
    end.to change(Absence, :count).by(1)

    expect(response).to redirect_to(transporter_path(transporter))
    expect(transporter.reload.off?).to be(true)
  end

  it 'rejects an absence without dates' do
    expect do
      post transporter_absences_path(transporter),
           params: { absence: { started_on: '', ended_on: '', reason: 'holidays' } }
    end.not_to change(Absence, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'updates an absence' do
    absence = create(:absence, transporter: transporter, reason: :holidays)

    patch transporter_absence_path(transporter, absence),
          params: { absence: { reason: 'disease' } }

    expect(response).to redirect_to(transporter_path(transporter))
    expect(absence.reload.reason).to eq('disease')
  end

  it 'deletes an absence' do
    absence = create(:absence, transporter: transporter)

    expect { delete transporter_absence_path(transporter, absence) }.to change(Absence, :count).by(-1)
  end

  it 'releases the steps of an absent driver' do
    stub_osrm!
    quest = create(:daily_quest, company: company)
    mission = create(:mission, daily_quest: quest, round_trip: false)
    step = mission.steps.first
    step.update!(transporter: transporter, status: :conflict)

    post transporter_absences_path(transporter),
         params: { absence: { started_on: quest.started_on, ended_on: quest.started_on, reason: 'holidays' } }

    expect(step.reload.transporter_id).to be_nil
    expect(step.status).to eq('possible')
  end

  it 'answers 404 for another company\'s driver' do
    get new_transporter_absence_path(create(:transporter, company: create(:company)))

    expect(response).to have_http_status(:not_found)
  end
end
