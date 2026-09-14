require 'rails_helper'

RSpec.describe 'Customers', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:customer) { create(:customer, company: company, first_name: 'Élodie', last_name: 'Nguyen') }

  before { sign_in(admin) }

  def customer_params(overrides = {})
    {
      first_name: 'Camille',
      last_name: 'Martin',
      address_attributes: { label: '10 rue de la Paix, 75002 Paris' }
    }.merge(overrides)
  end

  describe 'GET /customers' do
    it 'renders the list' do
      get customers_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Élodie Nguyen')
    end

    it 'filters by query across name and address' do
      other = create(:customer, company: company, first_name: 'Zoe', last_name: 'Zephyr')

      get customers_path, params: { search: { query: 'Nguyen' } }

      expect(response.body).to include('Élodie Nguyen')
      expect(response.body).not_to include(other.full_name)
    end

    it 'separates available from archived customers' do
      customer.archive!

      get customers_path
      expect(response.body).not_to include('Élodie Nguyen')

      get customers_path, params: { archived: 'true' }
      expect(response.body).to include('Élodie Nguyen')
    end

    it 'answers the map JSON' do
      get customers_path, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck('full_name')).to include('Élodie Nguyen')
    end

    it 'answers the Turbo Stream used by the live search' do
      get customers_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'does not show another company\'s customers' do
      create(:customer, company: create(:company), first_name: 'Intrus', last_name: 'Ailleurs')

      get customers_path

      expect(response.body).not_to include('Intrus Ailleurs')
    end
  end

  describe 'POST /customers' do
    it 'creates a customer and redirects to it' do
      expect { post customers_path, params: { customer: customer_params } }
        .to change(Customer, :count).by(1)

      expect(response).to redirect_to(customer_path(Customer.last))
      expect(Customer.last.company).to eq(company)
    end

    it 're-renders the form with the errors when invalid' do
      expect { post customers_path, params: { customer: customer_params(first_name: '') } }
        .not_to change(Customer, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('doit être rempli(e)')
    end

    it 'returns to the blank form in save-and-create-new mode' do
      post customers_path, params: { customer: customer_params, mode: 'save_and_create_new' }

      expect(response).to redirect_to(new_customer_path)
    end

    it 'refuses an unknown email format' do
      post customers_path, params: { customer: customer_params(email: 'not-an-email') }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Customer.last.email).to be_nil
    end
  end

  describe 'PATCH /customers/:id' do
    it 'updates the customer' do
      patch customer_path(customer), params: { customer: { first_name: 'Camille' } }

      expect(response).to redirect_to(customer_path(customer))
      expect(customer.reload.first_name).to eq('Camille')
    end

    it 're-renders the form when invalid' do
      patch customer_path(customer), params: { customer: { first_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(customer.reload.first_name).to eq('Élodie')
    end
  end

  describe 'DELETE /customers/:id' do
    it 'destroys the customer' do
      expect { delete customer_path(customer) }.to change(Customer, :count).by(-1)

      expect(response).to redirect_to(customers_path)
    end
  end

  describe 'DELETE /customers/:id/archive' do
    it 'archives and unarchives' do
      delete archive_customer_path(customer)
      expect(customer.reload).to be_archived

      delete archive_customer_path(customer)
      expect(customer.reload).to be_available
    end
  end

  describe 'GET /customers/daily' do
    it 'lists the customers of today\'s remaining steps' do
      get customers_path, as: :json
      expect(response).to have_http_status(:ok)

      get daily_customers_path, as: :json

      expect(response).to have_http_status(:ok)
    end
  end

  it 'answers 404 for another company\'s customer' do
    other = create(:customer, company: create(:company))

    get customer_path(other)

    expect(response).to have_http_status(:not_found)
  end
end
