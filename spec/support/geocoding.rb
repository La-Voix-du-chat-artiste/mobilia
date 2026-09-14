# Geocoder runs against its :test lookup in the test environment (see
# config/initializers/geocoder.rb), so address lookups are deterministic and
# offline. The stub payload mirrors the shape of the BAN API response that
# Address#geocoded_by parses.
module GeocodingHelpers
  PARIS = { latitude: 48.8686, longitude: 2.3314, street: 'Rue de la Paix',
            postcode: '75002', city: 'Paris' }.freeze
  LYON = { latitude: 45.7578, longitude: 4.8320, street: 'Place Bellecour',
           postcode: '69002', city: 'Lyon' }.freeze

  def stub_geocoding(**coordinates)
    attributes = PARIS.merge(coordinates)

    Geocoder::Lookup::Test.set_default_stub(
      [
        {
          'features' => [
            {
              'properties' => {
                'name' => attributes[:street],
                'postcode' => attributes[:postcode],
                'city' => attributes[:city]
              },
              'geometry' => {
                'coordinates' => [attributes[:longitude], attributes[:latitude]]
              }
            }
          ]
        }
      ]
    )
  end

  # Geocoding that finds nothing, which leaves latitude/longitude blank.
  def stub_failed_geocoding
    Geocoder::Lookup::Test.set_default_stub([])
  end

  def address_attributes(label: '10 rue de la Paix, 75002 Paris')
    { label: label }
  end
end

RSpec.configure do |config|
  config.include GeocodingHelpers
  config.before { stub_geocoding }
end
