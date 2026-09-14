require 'rails_helper'

# The job broadcasts progress messages into the browser, so it has to speak the
# language of the person who asked for the optimisation — a job runs outside that
# request, and job threads are reused, so the locale is passed in and put back.
RSpec.describe OptimizerJob do
  before do
    stub_osrm!
    allow(Step).to receive(:broadcast_flash)
    # ApplicationJob reports any exception it rescues as an alert broadcast; the
    # examples below assert on the notice, so keep the alert path out of the way.
    allow(ApplicationRecord).to receive(:broadcast_flash)
  end

  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:place) { create(:place, company: company) }
  let(:monday) { Date.current.beginning_of_week }
  let(:quest) { create(:daily_quest, company: company, started_on: monday) }
  let(:step) do
    create(:mission, daily_quest: quest, customer: customer, place: place, round_trip: false).steps.first
  end

  it 'broadcasts the progress in the language it is given' do
    described_class.perform_now([step.id], locale: 'en')

    expect(Step).to have_received(:broadcast_flash) do |_, message, **|
      expect(message).to include('Placing mission', 'The page is about to refresh')
    end
  end

  it 'puts the locale back when it is done' do
    described_class.perform_now([step.id], locale: 'zh')

    expect(I18n.locale).to eq(:fr)
  end

  it 'falls back to the default language for a locale it does not know' do
    described_class.perform_now([step.id], locale: 'klingon')

    expect(Step).to have_received(:broadcast_flash) do |_, message, **|
      expect(message).to include('Placement de la mission')
    end
  end
end
