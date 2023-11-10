class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy archive]

  # @route GET /customers (customers)
  def index
    authorize! Customer

    query = params.dig(:search, :query)
    @archived = params[:archived].present? && params[:archived] == 'true'

    customers = authorized_scope(
      company.customers,
      scope_options: { search_query: query, archived: @archived }
    )

    respond_to do |format|
      format.json { @customers = customers }
      format.html { @pagy, @customers = pagy(customers) }
      format.turbo_stream { @pagy, @customers = pagy(customers) }
    end
  end

  # @route GET /customers/new (new_customer)
  def new
    authorize! Customer

    @customer = company.customers.new
    @customer.build_address
  end

  # @route POST /customers (customers)
  def create
    authorize! Customer

    @customer = company.customers.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html do
          redirect_url = params[:mode] == 'save_and_create_new' ? new_customer_path : customer_path(@customer)
          redirect_to redirect_url, notice: 'Le client a bien été créé'
        end
        format.json { render :show, status: :created, location: @customer }
      else
        @customer.build_address(label: customer_params.dig(:address_attributes, :label))

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route GET /customers/:id (customer)
  def show
    authorize! @customer
  end

  # @route GET /customers/:id/edit (edit_customer)
  def edit
    authorize! @customer

    @customer.build_address if @customer.address.blank?
  end

  # @route PATCH /customers/:id (customer)
  # @route PUT /customers/:id (customer)
  def update
    authorize! @customer

    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to customer_path(@customer), notice: 'Le client a bien été mis à jour' }
        format.json { render :show, status: :ok, location: @customer }
      else
        @customer.build_address(label: customer_params.dig(:address_attributes, :label))

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # @route DELETE /customers/:id (customer)
  def destroy
    authorize! @customer

    @customer.destroy

    respond_to do |format|
      format.html { redirect_to customers_path, notice: 'Le client a bien été supprimé' }
      format.json { head :no_content }
    end
  end

  # @route DELETE /customers/:id/archive (archive_customer)
  def archive
    authorize! @customer

    if @customer.available?
      @customer.archive!
      flash[:notice] = 'Le client a bien été archivé'
    else
      @customer.unarchive!
      flash[:notice] = 'Le client a bien été désarchivé'
    end

    redirect_to customers_path
  end

  # @route GET /customers/daily (daily_customers)
  def daily
    authorize! Customer

    date = params[:date].presence || Date.current

    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)
    @steps = @daily_quest.steps.where('arrival_at > ?', Time.current - DailyQuest::WAITING_TIME.minutes)
    @missions = @steps.map(&:mission)
    @customers = @missions.map(&:customer).uniq.reject(&:archived?)

    respond_to do |format|
      format.json { render :index }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_customer
    @customer = company.customers.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def customer_params
    permitted_attributes = [
      :first_name, :last_name, :phone, :email, :kind, :enabled, :details,
      :favorite_trip_transporter_id, :favorite_trip_back_transporter_id,
      { address_attributes: %i[id label] }
    ]

    permitted_attributes.push(:photo) if options.enable_customer_photo?

    params.require(:customer).permit(permitted_attributes)
  end
end
