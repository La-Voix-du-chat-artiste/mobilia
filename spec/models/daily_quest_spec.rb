require 'rails_helper'

RSpec.describe DailyQuest do
  before { stub_osrm! }

  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company) }
  let(:place) { create(:place, company: company) }
  let(:monday) { Date.current.beginning_of_week }

  def quest_with_mission(date: monday, **)
    quest = create(:daily_quest, company: company, started_on: date)
    create(:mission, daily_quest: quest, customer: customer, place: place, **)
    quest
  end

  describe '.clone_week!' do
    it 'creates the matching quest one week later' do
      quest = quest_with_mission

      described_class.clone_week!(using: quest)

      expect(company.daily_quests.find_by(started_on: monday + 1.week)).to be_present
    end

    it 'copies every mission of the week' do
      quest = quest_with_mission

      described_class.clone_week!(using: quest)

      clone = company.daily_quests.find_by!(started_on: monday + 1.week)
      expect(clone.missions.count).to eq(quest.missions.count)
    end

    it 'preserves the drop duration' do
      quest = quest_with_mission(round_trip: true, drop_duration_hours: 2, drop_duration_minutes: 30)

      described_class.clone_week!(using: quest)

      clone = company.daily_quests.find_by!(started_on: monday + 1.week)
      expect(clone.missions.first.drop_duration).to eq(150)
    end

    # Cloning used `delete_all`, which skips `dependent: :destroy` on
    # Mission#steps, so the steps of the replaced missions stayed in the table
    # pointing at missions that no longer existed.
    it 'destroys the steps of the missions it replaces' do
      quest = quest_with_mission
      described_class.clone_week!(using: quest)
      clone = company.daily_quests.find_by!(started_on: monday + 1.week)
      replaced_step_ids = clone.steps.pluck(:id)

      expect(replaced_step_ids).not_to be_empty
      described_class.clone_week!(using: quest)

      expect(clone.reload.missions.count).to eq(quest.missions.count)
      expect(Step.where(id: replaced_step_ids)).to be_empty
      expect(Step.where.not(mission_id: Mission.select(:id))).to be_empty
    end

    it 'is a no-op for a week with no missions' do
      empty = create(:daily_quest, company: company, started_on: monday)
      other = quest_with_mission(date: monday + 3.months)

      expect { described_class.clone_week!(using: other) }.not_to raise_error
      expect(empty.reload.missions).to be_empty
    end
  end

  describe '#recompute_missions_position' do
    it 'numbers the missions by drop time' do
      quest = create(:daily_quest, company: company, started_on: monday)
      late = create(:mission, daily_quest: quest, customer: customer, place: place, drop_time: '15:00')
      early = create(:mission, daily_quest: quest, customer: customer, place: place, drop_time: '08:00')

      quest.recompute_missions_position

      expect(early.reload.position).to eq(1)
      expect(late.reload.position).to eq(2)
    end
  end

  describe '#title' do
    it 'renders the date through i18n' do
      quest = build(:daily_quest, started_on: Date.new(2026, 9, 14))

      expect(quest.title).to eq(I18n.l(Date.new(2026, 9, 14)))
    end
  end
end
