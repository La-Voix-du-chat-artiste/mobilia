require 'rails_helper'

RSpec.describe Transporter do
  let(:monday) { Date.current.beginning_of_week }

  def at(hour, date = monday)
    date.in_time_zone.change(hour: hour)
  end

  describe '#periods_for?' do
    it 'returns the declared period for the weekday' do
      transporter = build(:transporter, availabilities: { monday: 'morning' })

      expect(transporter.periods_for?(monday)).to eq(AvailabilitiesOption::PERIODS[:morning])
    end

    # availabilities is a json column defaulting to {} and the form only writes
    # the days it submits. This used to raise NoMethodError (nil.to_sym) out of
    # the optimizer.
    it 'falls back to no_work for a day nobody declared' do
      transporter = build(:transporter, :without_availabilities)

      expect { transporter.periods_for?(monday) }.not_to raise_error
      expect(transporter.periods_for?(monday)).to eq(AvailabilitiesOption::PERIODS[:no_work])
    end

    it 'falls back to no_work for a blank value' do
      transporter = build(:transporter, availabilities: { monday: '' })

      expect(transporter.periods_for?(monday)).to eq(AvailabilitiesOption::PERIODS[:no_work])
    end
  end

  describe '#available_at?' do
    let(:transporter) { build(:transporter, availabilities: { monday: 'morning' }) }

    it 'is true inside the declared window' do
      expect(transporter.available_at?(at(8), at(10))).to be(true)
    end

    it 'is false when the trip starts before the window' do
      expect(transporter.available_at?(at(5), at(9))).to be(false)
    end

    it 'is false when the trip ends after the window' do
      expect(transporter.available_at?(at(12), at(18))).to be(false)
    end

    it 'is false for a driver with no declared availability' do
      expect(build(:transporter, :without_availabilities).available_at?(at(8), at(10))).to be(false)
    end
  end

  describe '#sort_by_courses_for' do
    before { stub_osrm! }

    it 'orders drivers by how many of the day\'s steps they already have' do
      company = create(:company)
      quest = create(:daily_quest, company: company, started_on: monday)
      busy = create(:transporter, company: company)
      idle = create(:transporter, company: company)
      step = create(:mission, daily_quest: quest, round_trip: false).steps.first
      step.update!(transporter: busy)

      expect(described_class.sort_by_courses_for(quest)).to eq([idle, busy])
    end
  end
end
