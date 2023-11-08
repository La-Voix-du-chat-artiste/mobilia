class HomesController < ApplicationController
  layout 'home'

  # @route GET / (root)
  def show
    @refresh = true
    @refresh = false if params[:date] && params[:date].to_date != Date.current

    @refresh_map_interval = options.map_refresh_interval if @refresh

    @original_day = calendar.business_day?(parsed_date) ? parsed_date : calendar.next_business_day(parsed_date)
    @next_day = calendar.next_business_day(@original_day)
    @prev_day = calendar.previous_business_day(@original_day)
  end

  private

  def parsed_date
    @parsed_date ||= Date.parse(params[:date])
  rescue StandardError
    Date.current
  end
end
