require 'rails_helper'

RSpec.describe 'Planning', type: :request do
  before { stub_osrm! }

  let(:company) { create(:company) }
  let!(:admin) { create(:admin, company: company) }
  let!(:customer) { create(:customer, company: company) }
  let!(:place) { create(:place, company: company) }
  let!(:transporter) { create(:transporter, company: company) }
  # MissionPolicy#create? also requires a usable vehicle.
  let!(:vehicle) { create(:vehicle, company: company) }
  let(:calendar) { Business::Calendar.load_cached('targetfrance') }

  # A future business day, so the steps of the day are not "achieved" (a step
  # whose arrival time has passed can no longer be reassigned) and the board does
  # not redirect.
  let(:planning_day) do
    date = Date.current
    date = calendar.next_business_day(date) until calendar.business_day?(date)
    calendar.next_business_day(date)
  end

  let!(:quest) { create(:daily_quest, company: company, started_on: planning_day) }
  let!(:mission) { create(:mission, daily_quest: quest, customer: customer, place: place, round_trip: false) }
  let(:step) { mission.steps.first }

  before { sign_in(admin) }

  # Assigning a driver happens by dragging a step between columns; the Stimulus
  # controller PATCHes with a Turbo Stream Accept, and that is the only format
  # the action renders.
  def turbo_stream_headers
    { 'Accept' => 'text/vnd.turbo-stream.html' }
  end

  describe 'GET /daily_quests' do
    it 'renders the board' do
      get daily_quests_path(date: planning_day)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(transporter.full_name)
    end

    it 'creates the quest of the day when it does not exist yet' do
      another_day = calendar.next_business_day(planning_day)

      expect { get daily_quests_path(date: another_day) }.to change(DailyQuest, :count).by(1)
    end

    it 'moves a weekend request to the next business day' do
      get daily_quests_path(date: planning_day.end_of_week)

      expect(response).to be_redirect
    end

    # `step.started_at.round` used to call a monkey-patched Time#round that
    # rounded to five minutes AND converted to UTC, so the board showed times two
    # hours early in summer. The displayed time must be the application's.
    it 'shows the step times in the application time zone' do
      step.update!(started_at: planning_day.in_time_zone.change(hour: 9, min: 17),
                   arrival_at: planning_day.in_time_zone.change(hour: 10, min: 2))

      get daily_quests_path(date: planning_day)

      expect(response.body).to include('09h17')
    end
  end

  describe 'GET /daily_quests/:id' do
    it 'renders the mission details' do
      get daily_quest_path(quest)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(customer.full_name)
    end

    it 'focuses the mission asked for' do
      get daily_quest_path(quest, currentMissionId: mission.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /daily_quests/:id' do
    it 'removes every mission of the day' do
      expect { delete daily_quest_path(quest) }.to change(Mission, :count).by(-1)

      expect(response).to redirect_to(daily_quests_path)
    end
  end

  describe 'POST /daily_quests/:id/optimize' do
    it 'enqueues the optimizer for the unassigned steps' do
      expect { post optimize_daily_quest_path(quest) }.to have_enqueued_job(OptimizerJob)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /daily_quests/:id/duplicate_week' do
    it 'enqueues the duplication' do
      expect { post duplicate_week_daily_quest_path(quest) }.to have_enqueued_job(DuplicateWeekJob)

      expect(response).to redirect_to(daily_quests_path(date: quest.started_on))
    end
  end

  describe 'POST /daily_quests/:id/reset' do
    it 'unassigns every step of the day' do
      step.update!(transporter: transporter, status: :conflict)

      post reset_daily_quest_path(quest)

      expect(step.reload.transporter_id).to be_nil
      expect(step.status).to eq('possible')
    end
  end

  describe 'missions' do
    it 'lists them' do
      get daily_quest_missions_path(quest)

      expect(response).to have_http_status(:ok)
    end

    it 'creates one and generates its steps' do
      expect do
        post daily_quest_missions_path(quest), params: {
          mission: { drop_time: '11:00', round_trip: false,
                     customer_id: customer.id, place_id: place.id }
        }
      end.to change(Mission, :count).by(1)

      expect(Mission.last.steps.count).to eq(1)
      expect(response).to redirect_to(daily_quest_missions_path(quest))
    end

    it 'refuses one without a drop time' do
      expect do
        post daily_quest_missions_path(quest), params: {
          mission: { drop_time: '', round_trip: false,
                     customer_id: customer.id, place_id: place.id }
        }
      end.not_to change(Mission, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'shows one' do
      get daily_quest_mission_path(quest, mission)

      expect(response).to have_http_status(:ok)
    end

    it 'updates one' do
      patch daily_quest_mission_path(quest, mission), params: { mission: { drop_time: '14:30' } }

      expect(mission.reload.drop_time.strftime('%H:%M')).to eq('14:30')
    end

    it 'destroys one and its steps' do
      # Read the step before the request: `mission.steps` is empty afterwards.
      step_id = step.id

      expect { delete daily_quest_mission_path(quest, mission) }.to change(Mission, :count).by(-1)

      expect(Step.exists?(step_id)).to be(false)
    end
  end

  describe 'steps' do
    it 'assigns a driver to a step' do
      patch daily_quest_mission_step_path(quest, mission, step),
            params: { step: { transporter_id: transporter.id } },
            headers: turbo_stream_headers

      expect(step.reload.transporter_id).to eq(transporter.id)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end

    it 'unassigns a driver from a step' do
      step.update!(transporter: transporter)

      patch daily_quest_mission_step_path(quest, mission, step),
            params: { step: { transporter_id: '' } },
            headers: turbo_stream_headers

      expect(step.reload.transporter_id).to be_nil
    end

    it 'saves the driver note' do
      patch daily_quest_step_path(quest, step), params: { step: { description: 'Appeler avant de sonner' } }

      expect(step.reload.description.to_s).to include('Appeler avant de sonner')
      expect(response).to have_http_status(:ok)
    end

    it 'optimizes a single step onto the best driver' do
      post optimize_daily_quest_step_path(quest, step)

      expect(step.reload.transporter_id).to eq(transporter.id)
      expect(response).to redirect_to(daily_quests_path(date: quest.started_on))
    end

    it 'removes a step from the day' do
      expect { delete daily_quest_step_path(quest, step) }.to change(Step, :count).by(-1)

      expect(response).to redirect_to(daily_quests_path(date: quest.started_on))
    end
  end

  describe 'authorization' do
    it 'answers 404 for another company\'s quest' do
      get daily_quest_path(create(:daily_quest, company: create(:company)))

      expect(response).to have_http_status(:not_found)
    end

    it 'redirects a non-admin away from the optimizer' do
      sign_in(create(:user, company: company))

      post optimize_daily_quest_path(quest)

      expect(response).to be_redirect
    end
  end
end
