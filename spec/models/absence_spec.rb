require 'rails_helper'

RSpec.describe Absence do
  let(:transporter) { create(:transporter) }

  describe '.covering' do
    it 'returns the absences spanning the given day' do
      covering = create(:absence, transporter: transporter,
                                  started_on: Date.current - 1, ended_on: Date.current + 1)
      create(:absence, transporter: transporter,
                       started_on: Date.current + 10, ended_on: Date.current + 11)

      expect(described_class.covering(Date.current)).to contain_exactly(covering)
    end

    it 'accepts a Time as well as a Date' do
      covering = create(:absence, transporter: transporter, started_on: Date.current, ended_on: Date.current)

      expect(described_class.covering(Time.current)).to contain_exactly(covering)
    end
  end

  describe '#unassign_steps' do
    let(:mission) { create(:mission, customer: customer, place: place, daily_quest: quest, round_trip: false) }
    let(:customer) { create(:customer, company: company) }
    let(:place) { create(:place, company: company) }
    let(:quest) { create(:daily_quest, company: company) }
    let(:company) { transporter.company }
    let(:step) { mission.steps.first }

    before do
      stub_osrm!
      step.update!(transporter: transporter, status: :conflict)
    end

    it 'clears the transporter and puts the step back to :possible' do
      create(:absence, transporter: transporter, reason: :holidays)

      expect(step.reload.transporter_id).to be_nil
      expect(step.reload.status).to eq('possible')
    end

    # An "attending" absence means the driver is present, so nothing is released.
    it 'leaves the steps alone for an attending absence' do
      create(:absence, transporter: transporter, reason: :attending)

      expect(step.reload.transporter_id).to eq(transporter.id)
    end
  end
end

RSpec.describe Transporter, '#off?' do
  let(:transporter) { create(:transporter) }

  # `absences.present_today?` used to raise NoMethodError here: present_today?
  # was defined with `def self.` on Absence, so calling it through the association
  # blew up every planning screen that filters absent drivers.
  it 'reports an absent driver without raising' do
    create(:absence, transporter: transporter, started_on: Date.current, ended_on: Date.current + 2)

    expect(transporter.off?).to be(true)
    expect(transporter.off?(Date.current + 10)).to be(false)
  end

  it 'is not off for an attending absence' do
    create(:absence, transporter: transporter, reason: :attending)

    expect(transporter.off?).to be(false)
  end

  it 'is off when the absence covers the requested day only' do
    create(:absence, transporter: transporter,
                     started_on: Date.current + 3, ended_on: Date.current + 4)

    expect(transporter.off?(Date.current)).to be(false)
    expect(transporter.off?(Date.current + 3)).to be(true)
  end
end

RSpec.describe Transporter, '#current_absence' do
  let(:transporter) { create(:transporter) }

  it 'returns the non-attending absence covering the day' do
    absence = create(:absence, transporter: transporter, reason: :disease,
                               started_on: Date.current, ended_on: Date.current)

    expect(transporter.current_absence).to eq(absence)
  end

  it 'ignores attending absences' do
    create(:absence, transporter: transporter, reason: :attending)

    expect(transporter.current_absence).to be_nil
  end
end
