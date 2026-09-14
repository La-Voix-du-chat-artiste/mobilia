class Optimizer < ApplicationService
  attr_reader :daily_quest, :company, :step

  def initialize(step, daily_quest = nil)
    @step = step
    @daily_quest = daily_quest || @step.mission.daily_quest
    @company = @daily_quest.company
  end

  def call
    step.broadcast_pending_placement

    step_departure = step.departure_address
    step_arrival = step.arrival_address

    sorted_transporters = company.transporters.sort_by_courses_for(daily_quest)

    best_transporters = sorted_transporters.filter_map do |transporter|
      next if transporter.off?(daily_quest.started_on)
      next unless transporter.available_at?(step.started_at, step.arrival_at)
      # A step whose addresses were destroyed used to blow up with
      # "undefined method 'longitude' for nil".
      next if step_departure.nil? || step_arrival.nil?

      steps = transporter.steps.where(mission_id: daily_quest.mission_ids)

      previous_step = nil

      found_step = steps.find do |transporter_step|
        transporter_departure = transporter_step.departure_address
        next false if transporter_departure.nil?

        delta_departure = 0
        if previous_step
          previous_arrival = previous_step.arrival_address
          next false if previous_arrival.nil?

          delta_departure = Step.routing(departure_address: previous_arrival, arrival_address: step_departure, overview: 'simplified')['duration'].to_i
        end

        delta_arrival = Step.routing(departure_address: step_arrival, arrival_address: transporter_departure, overview: 'simplified')['duration'].to_i

        found = (previous_step ? step.started_at > (previous_step.arrival_at + delta_departure) : true) &&
                (step.arrival_at < (transporter_step.started_at + delta_arrival))
        previous_step = transporter_step

        found
      end

      if found_step # reste cas dernier transport de la journée
        distance = 0
        from = previous_step&.arrival_address
        to = step_departure

        distance += Step.routing(departure_address: from, arrival_address: to)['distance'].to_i if from

        from = step_arrival
        to = found_step.departure_address
      elsif previous_step.blank? ||
            (step.started_at > (previous_step.arrival_at + Step.routing(departure_address: previous_step.addresses.last, arrival_address: step_departure, overview: 'simplified')['duration'].to_i))

        distance = 0
        # Was `previous_step&.arrival_at`, a Time, which cannot be passed to
        # Step.routing as an address. Harmless only because of the `found_step`
        # guard on the next line.
        from = previous_step&.arrival_address
        to = step_departure
      else
        next
      end

      distance += Step.routing(departure_address: from, arrival_address: to)['distance'].to_i if found_step && from

      [transporter.id, distance.to_i]
    end

    # `min_by { |x, y| x.second <=> y.second }` only worked by accident: the
    # block destructures the pair, so `x.second` and `y.second` were
    # ActiveSupport::Duration built from the id and the distance.
    best = best_transporters.presence&.min_by(&:last)

    step.transporter_id = best&.first
    step.status = step.transporter_id.blank? ? :conflict : :possible
    step.save!

    step.broadcast_remove_from_unassigned_bucket
  end
end
