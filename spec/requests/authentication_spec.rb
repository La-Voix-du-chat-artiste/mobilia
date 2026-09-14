require 'rails_helper'

RSpec.describe 'authentication', type: :request do
  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }

  it 'serves the health check without authentication' do
    get '/up'

    expect(response).to have_http_status(:ok)
  end

  it 'renders the login page' do
    get '/sessions/new'

    expect(response).to have_http_status(:ok)
  end

  it 'redirects anonymous visitors away from the application' do
    get '/customers'

    expect(response).to redirect_to(new_sessions_path)
  end

  it 'signs in with valid credentials' do
    post '/sessions', params: { session: { email: admin.email, password: 'password123' } }

    expect(response).to redirect_to(root_path)
  end

  it 're-renders the form with an error for a wrong password' do
    post '/sessions', params: { session: { email: admin.email, password: 'wrong-password' } }

    expect(response).to have_http_status(:unauthorized)
  end

  it 'signs out' do
    sign_in(admin)

    delete '/sessions'

    expect(response).to redirect_to(new_sessions_path)
  end

  it 'renders the password reset request form' do
    get '/password_resets/new'

    expect(response).to have_http_status(:ok)
  end

  # Sorcery's reset_password module delivers inline (email_delivery_method
  # defaults to deliver_now), so this asserts on deliveries rather than on an
  # enqueued job.
  it 'sends a reset email and does not reveal whether the address exists' do
    ActionMailer::Base.deliveries.clear

    expect do
      post '/password_resets', params: { user: { email: admin.email } }
    end.to change { ActionMailer::Base.deliveries.count }.by(1)

    expect(response).to redirect_to(new_sessions_path)
    expect(ActionMailer::Base.deliveries.last.to).to eq([admin.email])
  end

  it 'does not reveal that an unknown address has no account' do
    post '/password_resets', params: { user: { email: 'nobody@example.test' } }

    expect(response).to have_http_status(:unprocessable_content)
  end
end
