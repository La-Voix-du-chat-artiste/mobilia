require 'rails_helper'

# pagy 9 renamed `:items` to `:limit` and changed `:size` from an array of slots
# to an integer number of page links. Both mistakes hide behind the same
# condition — a list needs more than one page — and `:size` is only validated
# inside the nav helper, so the application booted and the whole suite passed
# while the first paginated screen raised Pagy::VariableError.
RSpec.describe 'pagination', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }

  before do
    # More than one page at the configured size of 10, and fewer than pagy's
    # default of 20: the nav only renders if our :limit is honoured.
    create_list(:customer, 12, company: company)
    create_list(:place, 12, company: company)
    create_list(:vehicle, 12, company: company)
    create_list(:transporter, 12, company: company)

    sign_in(admin)
  end

  it 'uses the pagy 9 option names and types' do
    expect(Pagy::DEFAULT[:limit]).to eq(10)
    expect(Pagy::DEFAULT[:size]).to be_a(Integer)
  end

  ['/customers', '/places', '/vehicles', '/transporters'].each do |path|
    it "renders page links on #{path}" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('class="pagy nav"')
    end
  end

  it 'serves the second page' do
    get '/customers', params: { page: 2 }

    expect(response).to have_http_status(:ok)
  end

  it 'falls back to the last page when asked for one that does not exist' do
    get '/customers', params: { page: 99 }

    expect(response).to have_http_status(:ok)
  end
end
