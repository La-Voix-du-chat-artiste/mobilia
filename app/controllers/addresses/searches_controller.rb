module Addresses
  class SearchesController < ApplicationController
    # @route GET /addresses/search (addresses_search)
    def show
      results = Geocoder.search(params[:q])

      @results = results.first ? results.first.data['features'] : []
    end
  end
end
