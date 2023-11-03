module Transporters
  class AbsencesController < ApplicationController
    before_action :set_transporter
    before_action :set_absence, only: %i[edit update destroy]

    # @route GET /transporters/:transporter_id/absences/new (new_transporter_absence)
    def new
      authorize! Absence, context: { transporter: @transporter }

      @absence = @transporter.absences.new
    end

    # @route POST /transporters/:transporter_id/absences (transporter_absences)
    def create
      authorize! Absence, context: { transporter: @transporter }

      @absence = @transporter.absences.new(absence_params)

      respond_to do |format|
        if @absence.save
          format.html { redirect_to transporter_path(@transporter), notice: "L'absence a bien été créé" }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    # @route GET /transporters/:transporter_id/absences/:id/edit (edit_transporter_absence)
    def edit
      authorize! @absence, context: { transporter: @transporter }
    end

    # @route PATCH /transporters/:transporter_id/absences/:id (transporter_absence)
    # @route PUT /transporters/:transporter_id/absences/:id (transporter_absence)
    def update
      authorize! @absence, context: { transporter: @transporter }

      respond_to do |format|
        if @absence.update(absence_params)
          format.html { redirect_to transporter_path(@transporter), notice: "L'absence a bien été modifiée" }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    # @route DELETE /transporters/:transporter_id/absences/:id (transporter_absence)
    def destroy
      authorize! @absence, context: { transporter: @transporter }

      @absence.destroy

      respond_to do |format|
        format.html { redirect_to transporter_path(@transporter), notice: "L'absence a bien été supprimée" }
      end
    end

    private

    def set_transporter
      @transporter = company.transporters.find(params[:transporter_id])
    end

    def set_absence
      @absence = @transporter.absences.find(params[:id])
    end

    def absence_params
      params.require(:absence).permit(
        :started_on, :ended_on, :reason, :transporter_id
      )
    end
  end
end
