# Deterministic replacements for the three third-party calls the app makes.
# WebMock blocks everything else, so a spec that forgets one of these fails loudly
# instead of depending on the network.
module NetworkHelpers
  # Magic-byte prefixes: enough for Marcel (and so Active Storage) to sniff the type.
  def avatar_png_bytes
    "\x89PNG\r\n\x1A\n avatar".b
  end

  def avatar_jpeg_bytes
    "\xFF\xD8\xFF\xE0 avatar".b
  end

  # ui-avatars answers `format=jpg` requests with PNG, so PNG is the default
  # here: the stub should mirror what the service really does.
  def stub_avatars!(body: avatar_png_bytes, content_type: 'image/png')
    stub_request(:get, %r{\Ahttps://ui-avatars\.com/api/})
      .to_return(status: 200, body: body, headers: { 'Content-Type' => content_type })
  end

  def stub_avatars_timeout!
    stub_request(:get, %r{\Ahttps://ui-avatars\.com/api/}).to_timeout
  end

  # Two OSRM shapes: the encoded-polyline route used for Step#route, and the
  # GeoJSON one used for the positions drawn on the map. WebMock resolves
  # overlapping stubs last-declared-first, so the GeoJSON variant has to be
  # declared *after* the catch-all.
  def stub_osrm!(distance: 12_000, duration: 900, roads: ['Rue de la Paix'],
                 coordinates: [[2.3314, 48.8686], [4.8320, 45.7578]])
    stub_request(:get, %r{\Ahttps://router\.project-osrm\.org/route/v1/driving/})
      .to_return(
        status: 200,
        body: {
          routes: [
            {
              distance: distance,
              duration: duration,
              geometry: 'encoded-polyline',
              legs: [{ steps: roads.map { |name| { name: name } } }]
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, %r{\Ahttps://router\.project-osrm\.org/route/v1/driving/})
      .with(query: hash_including('geometries' => 'geojson'))
      .to_return(
        status: 200,
        body: { routes: [{ geometry: { type: 'LineString', coordinates: coordinates } }] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_osrm_failure!(status: 400)
    stub_request(:get, /router\.project-osrm\.org/).to_return(status: status, body: 'nope')
  end
end

RSpec.configure do |config|
  config.include NetworkHelpers
  # Avatars are fetched from inside after_create callbacks, so this has to be in
  # place before any factory runs.
  config.before { stub_avatars! }
end
