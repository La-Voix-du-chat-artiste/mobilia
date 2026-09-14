require 'rails_helper'

RSpec.describe Step do
  # `routing` only needs longitude/latitude/label, so these never touch the database.
  let(:paris) { Address.new(label: 'Paris', latitude: 48.8686, longitude: 2.3314) }
  let(:lyon) { Address.new(label: 'Lyon', latitude: 45.7578, longitude: 4.8320) }

  describe '.routing' do
    it 'parses distance, duration, geometry and road names' do
      stub_osrm!(distance: 465_500, duration: 18_060, roads: %w[A6 A7])

      route = described_class.routing(departure_address: paris, arrival_address: lyon)

      expect(route['distance']).to eq(465_500)
      expect(route['duration']).to eq(18_060)
      expect(route['geometry']).to eq('encoded-polyline')
      expect(route['roads']).to eq(%w[A6 A7])
    end

    # These all used to blow up as TypeError / "undefined method '[]' for nil".
    it 'raises RoutingError when OSRM answers with an error status' do
      stub_osrm_failure!(status: 400)

      expect { described_class.routing(departure_address: paris, arrival_address: lyon) }
        .to raise_error(described_class::RoutingError, /HTTP 400/)
    end

    it 'raises RoutingError when the body is not JSON' do
      stub_request(:get, /router\.project-osrm\.org/).to_return(status: 200, body: '<html>oops</html>')

      expect { described_class.routing(departure_address: paris, arrival_address: lyon) }
        .to raise_error(described_class::RoutingError, /non-JSON/)
    end

    it 'raises RoutingError when OSRM finds no route' do
      stub_request(:get, /router\.project-osrm\.org/)
        .to_return(status: 200, body: { routes: [] }.to_json)

      expect { described_class.routing(departure_address: paris, arrival_address: lyon) }
        .to raise_error(described_class::RoutingError, /no route from Paris to Lyon/)
    end

    it 'tolerates a leg with no named steps' do
      stub_request(:get, %r{router\.project-osrm\.org/route/v1/driving/})
        .to_return(status: 200, body: { routes: [{ distance: 1, duration: 2, geometry: 'g', legs: [] }] }.to_json)

      expect(described_class.routing(departure_address: paris, arrival_address: lyon)['roads']).to eq([])
    end
  end

  describe '#duration and #distance' do
    before { stub_osrm!(distance: 12_000, duration: 900) }

    it 'converts OSRM seconds into minutes and metres into kilometres' do
      step = create(:mission, round_trip: false).steps.first

      expect(step.duration).to eq(15)
      expect(step.distance).to eq(12.0)
    end
  end

  describe '#single?' do
    before { stub_osrm! }

    it 'is true while no transporter is assigned' do
      step = create(:mission, round_trip: false).steps.first

      expect(step).to be_single
      expect(described_class.single).to include(step)
    end
  end

  describe 'generated route' do
    before { stub_osrm! }

    it 'stores the geometry, the road names and both endpoints' do
      step = create(:mission, round_trip: false).steps.first

      expect(step.route['roads']).to eq(['Rue de la Paix'])
      expect(step.route.dig('coordinates', 'departure', 'label')).to eq('10 rue de la Paix, 75002 Paris')
      expect(step.route.dig('coordinates', 'arrival', 'label')).to eq('1 place Bellecour, 69002 Lyon')
      expect(step.route['positions']).to eq([[2.3314, 48.8686], [4.8320, 45.7578]])
    end

    it 'uses the generated icon helpers for the departure point' do
      step = create(:mission, round_trip: false).steps.first

      expect(step.departure_point_icon_starting_line?).to be(true)
      expect(step.arrival_point_icon_place?).to be(true)
    end
  end
end
