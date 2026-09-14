require 'rails_helper'

# Renders every page for real. This is the regression net for the Rails 8 enum
# breakage: a page only has to touch one model with an enum to blow up, and the
# suite has to notice.
RSpec.describe 'application pages', type: :request do
  before { stub_osrm! }

  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:customer) { create(:customer, company: company) }
  let!(:place) { create(:place, company: company) }
  let!(:vehicle) { create(:vehicle, company: company) }
  let!(:transporter) { create(:transporter, company: company) }

  # Picked from the app's own business calendar so the planning screens do not
  # redirect away on a weekend or a French holiday.
  let(:business_day) do
    calendar = Business::Calendar.load_cached('targetfrance')
    date = Date.current
    date = calendar.next_business_day(date) until calendar.business_day?(date)
    date
  end

  let!(:quest) { create(:daily_quest, company: company, started_on: business_day) }
  let!(:mission) do
    create(:mission, daily_quest: quest, customer: customer, place: place, round_trip: false)
  end

  before { sign_in(admin) }

  it 'renders the home page' do
    get '/'

    expect(response).to have_http_status(:ok)
  end

  [
    '/customers', '/customers/new',
    '/places', '/places/new',
    '/vehicles', '/vehicles/new',
    '/transporters', '/transporters/new',
    '/settings/edit',
    '/me/profile', '/me/profile/edit'
  ].each do |path|
    it "renders #{path}" do
      get path

      expect(response).to have_http_status(:ok)
    end
  end

  it 'renders the planning screen' do
    get "/daily_quests?date=#{business_day}"

    expect(response).to have_http_status(:ok)
  end

  it 'renders the record pages' do
    [
      customer_path(customer), edit_customer_path(customer),
      place_path(place), edit_place_path(place),
      vehicle_path(vehicle), edit_vehicle_path(vehicle),
      transporter_path(transporter), edit_transporter_path(transporter),
      new_transporter_absence_path(transporter),
      daily_quest_path(quest),
      daily_quest_missions_path(quest),
      daily_quest_mission_path(quest, mission),
      edit_daily_quest_mission_path(quest, mission)
    ].each do |path|
      get path

      expect(response).to have_http_status(:ok), "#{path} responded #{response.status}"
    end
  end

  describe "a driver's route sheet" do
    it 'renders with the steps assigned to that driver' do
      mission.steps.first.update!(transporter: transporter)

      get daily_quest_transporter_steps_path(quest, transporter)

      expect(response).to have_http_status(:ok)
    end

    # Used to answer 500: the partial called `steps.first.mission` on an empty
    # collection, so any driver with nothing planned that day took the page down.
    it 'renders when the driver has no steps at all' do
      idle = create(:transporter, company: company)

      get daily_quest_transporter_steps_path(quest, idle)

      expect(response).to have_http_status(:ok)
    end
  end

  it 'renders the JSON endpoints consumed by the maps' do
    ['/customers/daily', '/places/daily', '/transporters/daily'].each do |path|
      get path, as: :json

      expect(response).to have_http_status(:ok), "#{path} responded #{response.status}"
    end
  end

  it 'does not leak another company\'s record' do
    other = create(:customer, company: create(:company))

    get customer_path(other)

    expect(response).to have_http_status(:not_found)
  end

  describe 'mission management' do
    it 'creates a mission and generates its steps' do
      expect do
        post daily_quest_missions_path(quest), params: {
          mission: { drop_time: '11:00', round_trip: false,
                     customer_id: customer.id, place_id: place.id }
        }
      end.to change(Mission, :count).by(1)

      expect(response).to redirect_to(daily_quest_missions_path(quest))
    end

    it 're-renders the form when the mission is invalid' do
      post daily_quest_missions_path(quest), params: {
        mission: { drop_time: '', round_trip: false, customer_id: customer.id, place_id: place.id }
      }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'sending plannings' do
    # `company.daily_quests.with_attached_photo` raised NoMethodError here before.
    it 'redirects instead of raising when no step is assigned yet' do
      post send_all_plannings_daily_quest_transporters_path(quest)

      expect(response).to redirect_to(root_path)
    end

    it 'enqueues one planning email per available driver' do
      quest.steps.first.update!(transporter: transporter)

      expect do
        post send_all_plannings_daily_quest_transporters_path(quest)
      end.to have_enqueued_mail(TransporterMailer, :send_planning)
    end
  end
end
