class Optimizer < ApplicationService
  attr_reader :daily_quest, :company, :step

  def initialize(step, daily_quest = nil)
    @step = step
    @daily_quest = daily_quest || @step.mission.daily_quest
    @company = @daily_quest.company
  end

  def call
    step.broadcast_pending_placement

    sorted_transporters = company.transporters.sort_by_courses_for(daily_quest)

    best_transporters = sorted_transporters.filter_map do |transporter|
      next if transporter.off?(daily_quest.started_on)
      next unless transporter.available_at?(step.started_at, step.arrival_at)

      steps = transporter.steps.where(mission_id: daily_quest.mission_ids)

      previous_step = nil

      found_step = steps.find do |transporter_step|
        found = false

        delta_departure = Step.routing(departure_address: previous_step.addresses.last, arrival_address: step.addresses.first, overview: 'simplified')&.fetch('duration') if previous_step
        delta_arrival = Step.routing(departure_address: step.addresses.last, arrival_address: transporter_step.addresses.first, overview: 'simplified')&.fetch('duration')

        found = true if (previous_step ? step.started_at > (previous_step.arrival_at + delta_departure) : true) && (step.arrival_at < (transporter_step.started_at + delta_arrival))
        previous_step = transporter_step

        found
      end

      if found_step # reste cas dernier transport de la journée
        Rails.logger.info "   ***** step   #{found_step.inspect} *******  "

        distance = 0
        from = previous_step&.arrival_address
        to = step.departure_address

        Rails.logger.debug from
        Rails.logger.debug to

        distance += Step.routing(departure_address: from, arrival_address: to)['distance'].to_i if from
        Rails.logger.info "   *****1   #{distance} *******  "
        Rails.logger.debug ' *********** '
        from = step.arrival_address
        to = found_step&.departure_address

        Rails.logger.debug from
        Rails.logger.debug to
      elsif previous_step.blank? || (step.started_at > (previous_step.arrival_at + Step.routing(departure_address: previous_step.addresses.last, arrival_address: step.addresses.first, overview: 'simplified')&.fetch('duration')))

        distance = 0
        from = previous_step&.arrival_at
        to = step.addresses.first
      else
        next
      end

      distance += Step.routing(departure_address: from, arrival_address: to)['distance'].to_i if found_step && from
      Rails.logger.info "   *****2   #{distance} *******  "
      Rails.logger.debug distance
      Rails.logger.debug ' *** '
      founds = [transporter.id, distance.to_i]
      Rails.logger.info "   *************   #{founds} *************  "
      founds
    end

    best = nil
    best = best_transporters.min_by { |x, y| x.second <=> y.second } if best_transporters.present?

    step.transporter_id = best&.first
    step.status = step.transporter_id.blank? ? :conflict : :possible
    step.save!

    step.broadcast_remove_from_unassigned_bucket
  end
end
