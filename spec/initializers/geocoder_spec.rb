require 'rails_helper'

RSpec.describe 'Geocoder configuration' do
  # The BAN lookup builds its URL from Geocoder's `protocol`, which is "http"
  # unless use_https is set. geocoder 1.8.6 moved the endpoint to
  # data.geopf.fr, which does not answer on port 80: without this, every lookup
  # waited out the 15s timeout and returned nothing, so addresses silently ended
  # up with no coordinates and every generated mission failed to route.
  it 'queries the BAN endpoint over https' do
    expect(Geocoder.config[:use_https]).to be(true)
  end

  it 'resolves the lookup URL to https' do
    # Geocoder::Lookup.get loads and returns the lookup instance; the class is
    # not loaded in the test environment, which configures the :test lookup.
    lookup = Geocoder::Lookup.get(:ban_data_gouv_fr)
    query = Geocoder::Query.new('10 rue de la Paix 75002 Paris')

    expect(lookup.send(:query_url, query)).to start_with('https://')
  end
end
