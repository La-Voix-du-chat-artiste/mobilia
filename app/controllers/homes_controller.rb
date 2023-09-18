class HomesController < ApplicationController
  layout 'home'

  # @route GET / (root)
  def show
    @refresh = true
    @refresh = false if params[:date] && params[:date].to_date != Date.current

    @refresh_map_interval = options.map_refresh_interval if @refresh
  end
end
