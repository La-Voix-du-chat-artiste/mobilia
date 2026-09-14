require 'rails_helper'

# What each role can reach. Users are three roles -- standard, admin and
# super_admin -- and drivers are `Transporter < User` records (STI on `type`),
# so a standard user who logs in is a driver. Every administrative screen sits
# behind ApplicationPolicy#admin_up?.
RSpec.describe 'Authorization', type: :request do
  let(:company) { create(:company) }
  let!(:driver) { create(:transporter, company: company, first_name: 'Jean', last_name: 'Dupont') }
  let!(:other_driver) { create(:transporter, company: company, first_name: 'Marie', last_name: 'Durand') }
  let!(:admin) { create(:admin, company: company) }

  # `transporters_can_see_each_others` defaults to true: by default a driver may
  # look at the other drivers of the company.
  def keep_drivers_private!
    setting = company.setting
    setting.options.transporters_can_see_each_others = false
    setting.save!
  end

  describe 'as a driver' do
    before { sign_in(driver) }

    it 'reaches the planning board' do
      get daily_quests_path

      expect(response).to have_http_status(:ok)
    end

    it 'reaches its own profile' do
      get me_profile_path

      expect(response).to have_http_status(:ok)
    end

    it 'reaches its own driver page' do
      get transporter_path(driver)

      expect(response).to have_http_status(:ok)
    end

    %w[/customers /places /vehicles /settings/edit].each do |path|
      it "is turned away from #{path}" do
        get path

        expect(response).to be_redirect
      end
    end

    it 'is turned away from creating a customer' do
      get new_customer_path

      expect(response).to be_redirect
    end

    it 'is turned away from editing a customer' do
      get edit_customer_path(create(:customer, company: company))

      expect(response).to be_redirect
    end

    it 'cannot edit another driver' do
      get edit_transporter_path(other_driver)

      expect(response).to be_redirect
    end

    it 'sees the other drivers while the company allows it' do
      get transporters_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Jean Dupont', 'Marie Durand')
    end

    context 'when the company hides drivers from each other' do
      before { keep_drivers_private! }

      it 'only sees itself in the driver list' do
        get transporters_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Jean Dupont')
        expect(response.body).not_to include('Marie Durand')
      end

      it 'cannot read another driver' do
        get transporter_path(other_driver)

        expect(response).to be_redirect
      end
    end
  end

  describe 'as an admin' do
    before { sign_in(admin) }

    it 'reaches the administrative screens' do
      %w[/customers /places /vehicles /transporters /settings/edit].each do |path|
        get path

        expect(response).to have_http_status(:ok), "#{path} responded #{response.status}"
      end
    end

    it 'sees every driver of the company' do
      get transporters_path

      expect(response.body).to include('Jean Dupont', 'Marie Durand')
    end

    it 'sees every driver even when the company hides them from each other' do
      keep_drivers_private!

      get transporters_path

      expect(response.body).to include('Jean Dupont', 'Marie Durand')
    end
  end

  # A super admin is a role, not a way around tenancy: it still belongs to one
  # company and must not read another one's records.
  describe 'as a super admin of another company' do
    let!(:outsider) { create(:super_admin, company: create(:company)) }

    before { sign_in(outsider) }

    it 'does not list the customers of a company it does not belong to' do
      create(:customer, company: company, first_name: 'Élodie', last_name: 'Nguyen')

      get customers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Élodie Nguyen')
    end

    it 'answers 404 for a record of another company' do
      get customer_path(create(:customer, company: company))

      expect(response).to have_http_status(:not_found)
    end
  end
end
