class VehiclesController < ApplicationController
  before_action :set_vehicle, only: %i[show edit update destroy]

  # @route GET /vehicles (vehicles)
  def index
    authorize! Vehicle

    vehicles = authorized_scope(company.vehicles)

    @pagy, @vehicles = pagy(vehicles)
  end

  # @route GET /vehicles/new (new_vehicle)
  def new
    authorize! Vehicle

    @vehicle = company.vehicles.new
  end

  # @route POST /vehicles (vehicles)
  def create
    authorize! Vehicle

    @vehicle = company.vehicles.new(vehicle_params)

    respond_to do |format|
      if @vehicle.save
        format.html do
          redirect_url = params[:mode] == 'save_and_create_new' ? new_vehicle_path : vehicle_path(@vehicle)
          redirect_to redirect_url, notice: 'Le véhicule a bien été créé.'
        end
        format.json { render :show, status: :created, location: @vehicle }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route GET /vehicles/:id (vehicle)
  def show
    authorize! @vehicle
  end

  # @route GET /vehicles/:id/edit (edit_vehicle)
  def edit
    authorize! @vehicle
  end

  # @route PATCH /vehicles/:id (vehicle)
  # @route PUT /vehicles/:id (vehicle)
  def update
    authorize! @vehicle

    respond_to do |format|
      if @vehicle.update(vehicle_params)
        format.html { redirect_to vehicle_path(@vehicle), notice: 'Le véhicule a bien été mis à jour.' }
        format.json { render :show, status: :ok, location: @vehicle }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @vehicle.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route DELETE /vehicles/:id (vehicle)
  def destroy
    authorize! @vehicle

    @vehicle.destroy

    respond_to do |format|
      format.html { redirect_to vehicles_path, notice: 'Le véhicule a bien été supprimé.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_vehicle
    @vehicle = company.vehicles.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def vehicle_params
    permitted_attributes = %i[
      name number_plate width height length enabled
      details max_wheelchair_seats max_regular_seats
      status substitution
    ]

    permitted_attributes.push(:photo) if options.enable_vehicle_photo?

    params.require(:vehicle).permit(permitted_attributes)
  end
end
