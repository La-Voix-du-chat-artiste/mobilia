class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :protect_endpoint, only: %i[new create]

  layout 'session'

  # @route GET /users/new (new_user)
  def new
    @user = company.users.new
  end

  # @route POST /users (users)
  def create
    @user = company.users.new(user_params) do |u|
      u.role = :admin
    end

    respond_to do |format|
      if @user.save
        session[:company_id] = nil
        auto_login(@user)

        format.html { redirect_to root_path, notice: 'Votre compte administrateur a bien été créé' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :first_name, :last_name, :email,
      :password, :password_confirmation,
      :details, :photo
    )
  end

  def company
    @company ||= Company.find(session[:company_id])
  end

  def protect_endpoint
    if logged_in?
      redirect_to root_path
      return
    end

    return unless session[:company_id].nil?

    redirect_to new_companies_path
    nil
  end
end
