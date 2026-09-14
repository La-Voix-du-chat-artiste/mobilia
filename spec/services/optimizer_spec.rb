require 'rails_helper'

RSpec.describe Optimizer do
  before { stub_osrm! }

  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:place) { create(:place, company: company) }
  # A fixed weekday so `periods_for?` does not depend on the day the suite runs.
  let(:monday) { Date.current.beginning_of_week }
  let(:quest) { create(:daily_quest, company: company, started_on: monday) }
  let(:step) do
    create(:mission, daily_quest: quest, customer: customer, place: place, round_trip: false).steps.first
  end

  it 'assigns the only available transporter' do
    transporter = create(:transporter, company: company)

    described_class.call(step)

    expect(step.reload.transporter_id).to eq(transporter.id)
    expect(step.status).to eq('possible')
  end

  it 'picks the driver with the fewest steps already assigned that day' do
    busy = create(:transporter, company: company)
    idle = create(:transporter, company: company)
    other_step = create(:mission, daily_quest: quest, customer: customer, place: place, round_trip: false).steps.first
    other_step.update!(transporter: busy)

    described_class.call(step)

    expect(step.reload.transporter_id).to eq(idle.id)
  end

  it 'skips an absent driver and leaves the step in conflict' do
    absent = create(:transporter, company: company)
    create(:absence, transporter: absent, started_on: monday, ended_on: monday)

    described_class.call(step)

    expect(step.reload.transporter_id).to be_nil
    expect(step.status).to eq('conflict')
  end

  # Guards the periods_for? fix: an unconfigured driver must be skipped, not
  # raise NoMethodError out of the job.
  it 'skips a driver with no declared availability without raising' do
    create(:transporter, :without_availabilities, company: company)

    expect { described_class.call(step) }.not_to raise_error
    expect(step.reload.transporter_id).to be_nil
    expect(step.status).to eq('conflict')
  end

  it 'leaves the step in conflict when the company has no driver' do
    described_class.call(step)

    expect(step.reload.transporter_id).to be_nil
    expect(step.status).to eq('conflict')
  end
end
