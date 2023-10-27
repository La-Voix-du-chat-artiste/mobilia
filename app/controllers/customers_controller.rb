class CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy archive]

  # @route GET /customers (customers)
  def index
    customers = company.customers.includes(:address).with_attached_photo.with_all_rich_text.order(created_at: :desc)

    query = params.dig(:search, :query)
    customers = customers.by_query(query) if query.present?

    @archived = params[:archived].present? && params[:archived] == 'true'

    respond_to do |format|
      format.html do
        customers = @archived ? customers.archived : customers.available
        @pagy, @customers = pagy(customers)
      end

      format.json { @customers = customers.available }
      format.turbo_stream { @pagy, @customers = pagy(customers) }
    end
  end

  # @route GET /customers/daily (daily_customers)
  def daily
    date = params[:date].presence || Date.current

    @daily_quest = company.daily_quests.find_or_create_by(started_on: date)
    @steps = @daily_quest.steps.where('arrival_at > ?', Time.current - DailyQuest::WAITING_TIME.minutes)
    @missions = @steps.map(&:mission)
    @customers = @missions.map(&:customer).uniq.reject(&:archived?)

    respond_to do |format|
      format.json { render :index  }
    end
  end

  # @route GET /customers/new (new_customer)
  def new
    @customer = company.customers.new
    @customer.build_address
  end

  # @route POST /customers (customers)
  def create
    @customer = company.customers.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to customer_path(@customer), notice: 'Le client a bien été créé' }
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
  end

  # @route GET /customers/:id/edit (edit_customer)
  def edit
    @customer.build_address if @customer.address.blank?
  end

  # @route PATCH /customers/:id (customer)
  # @route PUT /customers/:id (customer)
  def update
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
    @customer.destroy

    respond_to do |format|
      format.html { redirect_to customers_path, notice: 'Le client a bien été supprimé' }
      format.json { head :no_content }
    end
  end

  # @route DELETE /customers/:id/archive (archive_customer)
  def archive
    if @customer.available?
      @customer.archive!
      flash[:notice] = 'Le client a bien été archivé'
    else
      @customer.unarchive!
      flash[:notice] = 'Le client a bien été désarchivé'
    end

    redirect_to customers_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_customer
    @customer = company.customers.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def customer_params
    params.require(:customer).permit(
      :first_name, :last_name, :phone, :email, :kind, :enabled,
      :details, :photo,
      :favorite_trip_transporter_id, :favorite_trip_back_transporter_id,
      address_attributes: %i[id label]
    )
  end
end
