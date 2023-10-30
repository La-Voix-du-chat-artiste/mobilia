class CompaniesController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :protect_endpoint, only: %i[new create]

  layout 'session', only: %i[new create]

  # @route GET /companies/new (new_companies)
  def new
    @company = Company.new
  end

  # @route POST /companies (companies)
  def create
    @company = Company.new(company_params)

    respond_to do |format|
      if @company.save
        session[:company_id] = @company.id
        format.html { redirect_to new_user_path, notice: "L'entreprise a bien été créée" }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # @route GET /companies/edit (edit_companies)
  def edit
    @company = current_user.company

    authorize! @company
  end

  # @route PATCH /companies (companies)
  # @route PUT /companies (companies)
  def update
    @company = current_user.company

    authorize! @company

    respond_to do |format|
      if @company.update(company_params)
        format.html { redirect_to root_path, notice: "L'entreprise a bien été mise à jour" }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def company_params
    params.require(:company).permit(:name, :logo, :description, :virtual_address)
  end

  def company_without_admin?
    @company ||= Company.find(session[:company_id])
    @company && @company.users.find_by(role: :admin).blank?
  rescue ActiveRecord::RecordNotFound
    false
  end

  def protect_endpoint
    if logged_in?
      redirect_to root_path
      return
    end

    return unless company_without_admin?

    redirect_to new_user_path
    nil
  end
end
