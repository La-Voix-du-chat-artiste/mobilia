require 'rails_helper'

RSpec.describe Mission do
  before { stub_osrm! }

  describe '#drop_duration' do
    it 'is computed from the virtual hour and minute attributes' do
      mission = build(:mission, drop_duration_hours: 1, drop_duration_minutes: 15)
      mission.valid?

      expect(mission.drop_duration).to eq(75)
    end

    # assign_drop_duration recomputed unconditionally, so any update that did not
    # resubmit the virtual attributes reset drop_duration to 0.
    it 'survives an update that does not supply the virtual attributes' do
      mission = create(:mission, round_trip: true, drop_duration_hours: 1, drop_duration_minutes: 15)

      mission.update!(drop_time: '10:00')

      expect(mission.reload.drop_duration).to eq(75)
    end

    it 'defaults to 0 when a new record supplies neither attribute' do
      expect(create(:mission, round_trip: false).drop_duration).to eq(0)
    end
  end

  describe '#drop_datetime' do
    it 'combines the quest date with the drop time in the application time zone' do
      quest = create(:daily_quest, started_on: Date.new(2026, 9, 14))
      mission = create(:mission, daily_quest: quest, drop_time: '09:30')

      expect(mission.drop_datetime).to eq(Time.zone.local(2026, 9, 14, 9, 30))
    end
  end

  describe 'step generation' do
    it 'creates one step for a one-way mission' do
      expect { create(:mission, round_trip: false) }.to change(Step, :count).by(1)
    end

    it 'creates two steps for a round trip' do
      expect { create(:mission, round_trip: true, drop_duration_minutes: 30) }
        .to change(Step, :count).by(2)
    end

    it 'regenerates the steps when the mission changes' do
      mission = create(:mission, round_trip: false)
      step_ids = mission.step_ids

      mission.update!(drop_time: '11:00')

      expect(mission.reload.step_ids).not_to eq(step_ids)
      expect(Step.where(id: step_ids)).to be_empty
    end
  end

  describe '#by_position' do
    it 'orders by the stored position' do
      quest = create(:daily_quest)
      late = create(:mission, daily_quest: quest, drop_time: '15:00', position: 2)
      early = create(:mission, daily_quest: quest, drop_time: '08:00', position: 1)

      expect(quest.missions.by_position.to_a).to eq([early, late])
    end
  end
end
