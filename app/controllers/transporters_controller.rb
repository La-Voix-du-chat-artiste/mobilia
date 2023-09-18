class TransportersController < ApplicationController
  before_action :set_transporter, only: %i[show edit update destroy]

  # @route GET /transporters (transporters)
  def index
    transporters = company.transporters.includes(:address, :vehicle).with_attached_photo.with_all_rich_text

    respond_to do |format|
      format.html { @pagy, @transporters = pagy(transporters) }
      format.json { @transporters = transporters }
    end
  end

  # @route GET /transporters/daily (daily_transporters)
  def daily
    date = params[:date].presence || Date.current

    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)

    transporters_by_ids = {}

    steps_done = @daily_quest.steps.where('(arrival_at  < ?)  ', Time.current)

    steps_done.each do |step|
      next unless (transporter = step.transporter)

      transporters_by_ids[transporter.id] = step # uniquifier
    end

    steps_doing = @daily_quest.steps.where('(started_at  < ? and arrival_at  > ?)  ', Time.current, Time.current)

    # get remaining steps by reverse, that way we keep to get the first as last
    steps_doing.each do |step|
      next unless (transporter = step.transporter)

      transporters_by_ids[transporter.id] = step # uniquifier
    end

    @transporters = []
    transporters_by_ids.each do |_id, step|
      transporter = step.transporter
      locations = step.route['positions']

      step_duration = step.arrival_at - step.started_at
      remaining_duration = step.arrival_at - Time.current
      done_duration = step_duration - remaining_duration + 0.01

      Rails.logger.info remaining_duration
      if remaining_duration.negative?
        transporter.driving = false
        longitude, latitude = locations.last
        Rails.logger.info "#{step.title}  ******* #{transporter.first_name} #{transporter.last_name} stopped @ [#{longitude} ,  #{latitude}] for #{step.arrival_at} ******* "
      else
        transporter.driving = true
        nb_locations = locations.count
        no_point = (done_duration / step_duration.to_f * nb_locations).floor

        longitude, latitude = locations[no_point]
        Rails.logger.info " #{step.title} #{remaining_duration} | #{done_duration} / #{step_duration.to_f} * #{nb_locations} ******* #{transporter.inspect} running @ #{no_point}:  [#{longitude} ,  #{latitude}] ******* "
      end

      transporter.latitude = latitude
      transporter.longitude = longitude
      @transporters << transporter
    end

    # Add missing transporters to be shown on map
    # at their home address.
    transporter_ids = @transporters.map(&:id)
    @transporters << company.transporters.where.not(id: transporter_ids)
    @transporters = @transporters.flatten

    respond_to do |format|
      format.json { render :index }
    end
  end

  # @route GET /transporters/new (new_transporter)
  def new
    @transporter = company.transporters.new
    @transporter.build_address
  end

  # @route POST /transporters (transporters)
  def create
    @transporter = company.transporters.new(transporter_params)

    respond_to do |format|
      if @transporter.save
        format.html { redirect_to transporter_url(@transporter), notice: 'Le chauffeur a bien été créé.' }
        format.json { render :show, status: :created, location: @transporter }
      else
        @transporter.build_address(label: transporter_params.dig(:address_attributes, :label))

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @transporter.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route GET /transporters/:id (transporter)
  def show
    @pagy, @absences = pagy(@transporter.absences.order(started_on: :desc))
  end

  # @route GET /transporters/:id/edit (edit_transporter)
  def edit
    @transporter.build_address if @transporter.address.blank?
  end

  # @route PATCH /transporters/:id (transporter)
  # @route PUT /transporters/:id (transporter)
  def update
    respond_to do |format|
      if @transporter.update(transporter_params)
        format.html { redirect_to transporter_url(@transporter), notice: 'Le chauffeur a bien été mis à jour.' }
      else
        @transporter.build_address(label: transporter_params.dig(:address_attributes, :label))

        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # @route DELETE /transporters/:id (transporter)
  def destroy
    @transporter.destroy

    respond_to do |format|
      format.html { redirect_to transporters_url, notice: 'Le chauffeur a bien été supprimé.' }
      format.json { head :no_content }
    end
  end

  private

  def set_transporter
    @transporter = company.transporters.find(params[:id])
  end

  def transporter_params
    params.require(:transporter).permit(
      :first_name, :last_name, :email, :phone,
      :started_time, :ended_time, :details, :photo,
      :vehicle_id, availabilities: %i[
                     monday tuesday wednesday thursday
                     friday saturday sunday
                   ],
                   address_attributes: %i[id label]
    )
  end
end
