module Me
  class ProfilesController < ApplicationController
    before_action :require_login

    # @route GET /me/profile (me_profile)
    def show
      authorize! current_user, with: ProfilePolicy
    end

    # @route GET /me/profile/edit (edit_me_profile)
    def edit
      authorize! current_user, with: ProfilePolicy
    end

    # @route PATCH /me/profile (me_profile)
    # @route PUT /me/profile (me_profile)
    def update
      authorize! current_user, with: ProfilePolicy

      current_user.photo.purge if user_params[:remove_photo] == '1'

      if current_user.update(user_params)
        redirect_to me_profile_path, notice: 'Votre profil a bien été mis à jour'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :email, :phone, :photo, :remove_photo
      )
    end
  end
end
