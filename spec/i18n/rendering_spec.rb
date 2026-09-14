require 'rails_helper'

# Every page, in every language. The test environment raises on missing
# translations, so a key that only exists in French fails here rather than
# showing "translation missing" to someone reading the Chinese interface.
#
# The page list mirrors spec/requests/pages_spec.rb on purpose: that file is the
# regression net for the pages themselves, this one for their translations.
RSpec.describe 'Internationalization', type: :request do
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

  def authenticated_paths
    [
      '/',
      '/customers', '/customers/new',
      customer_path(customer), edit_customer_path(customer),
      '/places', '/places/new',
      place_path(place), edit_place_path(place),
      '/vehicles', '/vehicles/new',
      vehicle_path(vehicle), edit_vehicle_path(vehicle),
      '/transporters', '/transporters/new',
      transporter_path(transporter), edit_transporter_path(transporter),
      new_transporter_absence_path(transporter),
      '/settings/edit',
      '/me/profile', '/me/profile/edit',
      '/companies/edit',
      daily_quests_path(date: business_day),
      daily_quest_path(quest),
      daily_quest_missions_path(quest),
      daily_quest_mission_path(quest, mission),
      edit_daily_quest_mission_path(quest, mission)
    ]
  end

  # /users/new is not here: it is only reachable while no company exists yet (it
  # redirects afterwards), and spec/features/onboarding_spec.rb covers it.
  def public_paths
    ['/sessions/new', '/password_resets/new', '/companies/new']
  end

  describe 'the language switcher' do
    before { sign_in(admin) }

    it 'renders the page in the requested language' do
      get customers_path, params: { locale: :en }

      expect(response.body).to include('Customers | Mobilia')
    end

    it 'remembers the language for the rest of the session' do
      get customers_path, params: { locale: :zh }
      expect(response.body).to include('客户列表 | Mobilia')

      get customers_path

      expect(response.body).to include('客户列表 | Mobilia')
    end

    it 'offers every language and marks the current one' do
      get customers_path, params: { locale: :en }

      expect(response.body).to include('Français', 'English', '中文')
      expect(response.body).to match(/aria-current="true"[^>]*>English/)
    end

    it 'falls back to French for a language it does not speak' do
      get customers_path, params: { locale: :klingon }

      expect(response.body).to include('Les clients | Mobilia')
    end

    it 'leaves the locale as it found it for the next request' do
      get customers_path, params: { locale: :en }

      expect(I18n.locale).to eq(:fr)
    end
  end

  describe 'every authenticated page' do
    before { sign_in(admin) }

    I18n.available_locales.each do |locale|
      it "renders in #{locale}" do
        authenticated_paths.each do |path|
          get path, params: { locale: locale }

          expect(response).to have_http_status(:ok), "#{path} in #{locale} responded #{response.status}"
          expect(response.body).not_to include('translation missing'), "#{path} in #{locale}"
        end
      end
    end
  end

  describe 'every public page' do
    I18n.available_locales.each do |locale|
      it "renders in #{locale}" do
        public_paths.each do |path|
          get path, params: { locale: locale }

          expect(response).to have_http_status(:ok), "#{path} in #{locale} responded #{response.status}"
        end
      end
    end
  end
end
