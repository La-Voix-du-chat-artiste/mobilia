class PlacesController < ApplicationController
  before_action :set_place, only: %i[show edit update destroy]

  # @route GET /places (places)
  def index
    authorize! Place

    query = params.dig(:search, :query)

    places = authorized_scope(
      company.places, scope_options: { search_query: query }
    )

    respond_to do |format|
      format.json { @places = places }
      format.html { @pagy, @places = pagy(places) }
      format.turbo_stream { @pagy, @places = pagy(places) }
    end
  end

  # @route GET /places/new (new_place)
  def new
    authorize! Place

    @place = company.places.new
    @place.build_address
  end

  # @route POST /places (places)
  def create
    authorize! Place

    @place = company.places.new(place_params)

    respond_to do |format|
      if @place.save
        format.html do
          redirect_url = params[:mode] == 'save_and_create_new' ? new_place_path : place_path(@place)
          redirect_to redirect_url, notice: 'Le lieu a été créé.'
        end
        format.json { render :show, status: :created, location: @place }
      else
        @place.build_address(label: place_params.dig(:address_attributes, :label))

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route GET /places/:id (place)
  def show
    authorize! @place
  end

  # @route GET /places/:id/edit (edit_place)
  def edit
    authorize! @place
  end

  # @route PATCH /places/:id (place)
  # @route PUT /places/:id (place)
  def update
    authorize! @place

    respond_to do |format|
      if @place.update(place_params)
        format.html { redirect_to place_url(@place), notice: 'Le lieu a été mis à jour.' }
        format.json { render :show, status: :ok, location: @place }
      else
        @place.build_address(label: place_params.dig(:address_attributes, :label))

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @place.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route DELETE /places/:id (place)
  def destroy
    authorize! @place

    @place.destroy

    respond_to do |format|
      format.html { redirect_to places_url, notice: 'Le lieu a été supprimé.' }
      format.json { head :no_content }
    end
  end

  # @route GET /places/daily (daily_places)
  def daily
    authorize! Place

    date = params[:date].presence || Date.current

    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)
    @steps = @daily_quest.steps.where('arrival_at > ?', Time.current - DailyQuest::WAITING_TIME.minutes)

    @missions = @steps.map(&:mission)
    @places = @missions.map(&:place).uniq

    respond_to do |format|
      format.json { render :index }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_place
    @place = company.places.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def place_params
    permitted_attributes = [
      :name, :phone, :email, :enabled, :details,
      { address_attributes: %i[id label] }
    ]

    permitted_attributes.push(:photo) if options.enable_place_photo?

    params.require(:place).permit(permitted_attributes)
  end
end
