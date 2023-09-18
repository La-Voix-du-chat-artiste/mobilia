class GenerateQuestDemo < ApplicationService
  START = 9
  DURATIONS = [30, 60, 90].freeze

  attr_reader :started_on, :quest

  def initialize(company, started_on = Date.current)
    @company = company
    Rails.logger.debug { "GenerateQuestDemo  for #{started_on}" }
    @quest = @company.daily_quests.find_or_create_by(started_on: started_on)
  end

  def call
    clients = @company.customers.enabled.sample(16)

    delta = START

    clients.each_with_index do |client, i_time|
      duration = DURATIONS.sample

      mission = Mission.new(
        drop_time: "#{delta}:00",
        drop_duration: duration,
        customer: client,
        place: @company.places.enabled.sample
      )
      Rails.logger.debug client.full_name.to_s

      delta += ((duration + 30) / 60.to_f).ceil
      delta += 2 if i_time == 3

      @quest.missions << mission

      delta = START if (i_time % 5).zero?
    end
  end
end
