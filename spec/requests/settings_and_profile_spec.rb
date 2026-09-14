require 'rails_helper'

RSpec.describe 'Settings and profile', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }

  before { sign_in(admin) }

  describe 'GET /settings/edit' do
    it 'renders the settings form' do
      get edit_settings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Paramètres')
    end
  end

  describe 'PATCH /settings' do
    it 'updates the options and redirects to the dashboard' do
      patch settings_path, params: {
        setting: { options: { theme: 'light', delta_jam: 12, show_help: false } }
      }

      expect(response).to redirect_to(root_path)

      setting = company.setting.reload
      expect(setting.options.theme).to eq('light')
      expect(setting.options.delta_jam).to eq(12)
      expect(setting.options.show_help).to be(false)
    end

    it 'keeps the untouched options at their defaults' do
      patch settings_path, params: { setting: { options: { theme: 'light' } } }

      expect(company.setting.reload.options.transporters_can_see_each_others).to be(true)
    end

    it 'refuses an out-of-range value' do
      patch settings_path, params: { setting: { options: { theme: 'light', delta_jam: -5 } } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(company.setting.reload.options.delta_jam).to eq(8)
    end

    it 'turns the planning board photo options off' do
      patch settings_path, params: { setting: { options: { enable_customer_photo: false } } }

      expect(company.setting.reload.options.enable_customer_photo).to be(false)
    end
  end

  describe 'me/profile' do
    it 'renders the profile' do
      get me_profile_path

      expect(response).to have_http_status(:ok)
    end

    it 'updates the current user' do
      patch me_profile_path, params: { transporter: { first_name: 'Camille', last_name: 'Martin' } }

      expect(response).to redirect_to(me_profile_path)
      expect(admin.reload.first_name).to eq('Camille')
      expect(admin.last_name).to eq('Martin')
    end

    it 'never lets the profile change the company or the role' do
      other_company = create(:company)

      patch me_profile_path, params: {
        transporter: { first_name: 'Camille', company_id: other_company.id, role: 'super_admin' }
      }

      expect(admin.reload.company).to eq(company)
      expect(admin).not_to be_super_admin
    end

    it 'refuses an invalid email' do
      patch me_profile_path, params: { transporter: { email: 'not-an-email' } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'purges the photo when asked to' do
      expect(admin.photo).to be_attached

      patch me_profile_path, params: { transporter: { remove_photo: '1', first_name: admin.first_name, last_name: admin.last_name } }

      expect(admin.reload.photo).not_to be_attached
    end
  end
end
