class SettingsController < ApplicationController
  before_action :set_setting, only: %i[edit update]

  # @route GET /settings/edit (edit_settings)
  def edit
    authorize! @setting

    @setting.build_address if @setting.address.blank?
  end

  # @route PATCH /settings (settings)
  # @route PUT /settings (settings)
  def update
    authorize! @setting

    respond_to do |format|
      if @setting.update(setting_params)
        format.html { redirect_to root_path, notice: 'Les paramètres ont bien été mis à jour.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_setting
    @setting = company.setting
  end

  def setting_params
    params.require(:setting).permit(
      options: {}, address_attributes: %i[id label]
    )
  end
end
