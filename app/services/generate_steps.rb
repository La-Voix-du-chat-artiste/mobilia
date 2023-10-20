class GenerateSteps < ApplicationService
  attr_reader :daily_quest, :mission

  def initialize(daily_quest, mission)
    @daily_quest = daily_quest
    @mission = mission
  end

  def call
    # if missions.first == mission
    #   transporter_home_to_customer_home
    # else
    #   transporter_last_dropped_mission_step_to_customer_home
    # end

    step_1 = customer_home_to_place
    step_2 = place_to_customer_home

    [step_1, step_2]
    # customer_home_to_transporter_home if missions.last == mission
  end

  private

  # Step 1
  def customer_home_to_place
    step_1 = mission.steps.create!(
      title: [mission.customer.full_name, mission.place.name].join(' >> '),
      departure_point_icon: :starting_line,
      arrival_point_icon: :place,
      arrival_at: mission.drop_datetime, # Arrival time to place
      role: 'customer_to_place',
      addresses: [customer.address.dup, place.address.dup]
    )

    step_1.started_at = step_1.arrival_at - (step_1.duration.minutes + step_1.jam + step_1.delta)
    step_1.transporter = trip_transporter_for(step_1.started_at, step_1.arrival_at)

    step_1.save!
  end

  # Step 2
  def place_to_customer_home
    step_2 = mission.steps.create!(
      title: [mission.place.name, mission.customer.full_name].join(' >> '),
      departure_point_icon: :place,

      arrival_point_icon: :ending_line,
      role: 'place_to_customer',
      started_at: return_back_at,
      addresses: [place.address.dup, customer.address.dup]
    )

    step_2.arrival_at = step_2.started_at + (step_2.duration.minutes + step_2.jam + step_2.delta)
    step_2.transporter = trip_back_transporter_for(step_2.started_at, step_2.arrival_at)

    step_2.save!
  end

  def trip_transporter_for(started_at, arrival_at)
    favorite = customer.favorite_trip_transporter
    favorite if favorite&.available_at?(started_at, arrival_at)
  end

  def trip_back_transporter_for(started_at, arrival_at)
    favorite = customer.favorite_trip_back_transporter
    favorite if favorite&.available_at?(started_at, arrival_at)
  end

  def place
    mission.place
  end

  def customer
    mission.customer
  end

  def return_back_at
    mission.drop_datetime + mission.drop_duration.minutes
  end

  def missions
    daily_quest.missions.order(drop_time: :asc)
  end
end
