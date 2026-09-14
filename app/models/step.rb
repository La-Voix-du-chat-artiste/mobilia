class Step < ApplicationRecord
  include ActionView::Helpers::AssetUrlHelper
  include Rails.application.routes.url_helpers

  # Raised when the OSRM routing service cannot answer, or answers something we
  # cannot use. Routing used to fail with an opaque TypeError/NoMethodError
  # ("undefined method '[]' for nil") coming from a nil response body or a nil
  # `routes` entry, which said nothing about what actually went wrong.
  class RoutingError < StandardError; end

  OSRM_ENDPOINT = 'https://router.project-osrm.org'.freeze

  # Rails 8 removed the `enum name: {...}` keyword form (it now raises
  # ArgumentError) and the `_prefix` / `_default` style options. Enums must be
  # declared positionally.
  enum :role, {
    transporter_to_customer: 0,
    customer_to_place: 1,
    place_to_customer: 2,
    customer_to_transporter: 3,
    customer_to_customer: 4
  }
  enum :status, {
    possible: 0,
    conflict: 1,
    impossible: 2
  }
  enum :departure_point_icon, {
    starting_line: 0, transporter: 1, customer: 2, place: 3, ending_line: 4
  }, prefix: true
  enum :arrival_point_icon, {
    starting_line: 0, transporter: 1, customer: 2, place: 3, ending_line: 4
  }, prefix: true

  belongs_to :transporter, optional: true
  belongs_to :mission

  has_many :addresses, class_name: 'Address', as: :addressable, dependent: :destroy

  has_rich_text :description

  default_scope -> { order(:started_at) }
  scope :single, -> { where.missing(:transporter) }

  before_save :generate_route, if: ->(step) { step.route.blank? }

  def self.osrm_json(path)
    response = Faraday.get("#{OSRM_ENDPOINT}#{path}")

    raise RoutingError, "OSRM request failed with HTTP #{response.status} for #{path}" unless response.success?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise RoutingError, "OSRM returned a non-JSON body for #{path}: #{e.message}"
  end
  private_class_method :osrm_json

  # The distinct road names OSRM reports for the first leg, used by the PDF.
  def self.roads_from(route)
    legs = route['legs'] || []
    steps = legs.first&.fetch('steps', nil) || []

    steps.filter_map { |step| step['name'] }.uniq
  end
  private_class_method :roads_from

  def self.routing(departure_address:, arrival_address:, overview: 'false', geometries: 'polyline')
    coords_string = "#{departure_address.longitude},#{departure_address.latitude};#{arrival_address.longitude},#{arrival_address.latitude}"

    json = osrm_json("/route/v1/driving/#{coords_string}?overview=#{overview}&steps=#{!overview.nil?}&geometries=#{geometries}&alternatives=false")

    route = json['routes']&.first

    raise RoutingError, "OSRM found no route from #{departure_address.label} to #{arrival_address.label}" if route.nil?

    route['roads'] = roads_from(route)

    route.slice('distance', 'duration', 'geometry', 'roads')
  end

  def self.routing_match(addresses)
    all_coords = addresses.map(&:coords)

    stringify_coords = all_coords.map { |c| c.join(',') }.join(';')

    trip_params = "#{stringify_coords}?source=first&destination=last&geometries=polyline&steps=true&roundtrip=false&overview=full"
    json = osrm_json("/trip/v1/driving/#{trip_params}")
    route = json['trips']&.first

    raise RoutingError, 'OSRM found no trip for the given addresses' if route.nil?

    route['roads'] = roads_from(route)

    route['waypoints_index'] = json.fetch('waypoints', []).pluck('waypoint_index')
    route.slice('distance', 'duration', 'geometry', 'roads', 'waypoints_index')
  end

  def single?
    transporter.blank?
  end

  def jam
    options.delta_jam.minutes * duration / 60.to_f
  end

  def delta
    return 0 unless mission.customer&.in_wheelchair?

    options.delta_loading.minutes.to_i
  end

  def departure_address
    addresses.first
  end

  def arrival_address
    addresses.second
  end

  def routing(overview: 'full', geometries: 'polyline')
    Step.routing(departure_address: departure_address, arrival_address: arrival_address, overview: overview, geometries: geometries)
  end

  def generate_route
    self.route = routing

    route_with_positions = routing(overview: 'simplified', geometries: 'geojson')
    route[:positions] = route_with_positions&.fetch('geometry')&.fetch('coordinates')

    departure_icon_url = case departure_point_icon.to_sym
                         when :starting_line
                           image_path('/green-flag.png')
                         when :transporter
                           polymorphic_path(transporter.photo, only_path: true)
                         when :customer
                           polymorphic_path(mission.customer.photo, only_path: true)
                         when :place
                           polymorphic_path(mission.place.photo, only_path: true)
                         when :ending_line
                           :default
    end

    arrival_icon_url = case arrival_point_icon.to_sym
                       when :starting_line
                         :default
                       when :transporter
                         polymorphic_path(transporter.photo, only_path: true)
                       when :customer
                         polymorphic_path(mission.customer.photo, only_path: true)
                       when :place
                         polymorphic_path(mission.place.photo, only_path: true)
                       when :ending_line
                         image_path('/black-flag.png')
    end
    # end

    route[:coordinates] = {
      departure: {
        latitude: departure_address.latitude,
        longitude: departure_address.longitude,
        label: departure_address.label,
        icon_type: departure_point_icon,
        icon_url: departure_icon_url
      },
      arrival: {
        latitude: arrival_address.latitude,
        longitude: arrival_address.longitude,
        label: arrival_address.label,
        icon_type: arrival_point_icon,
        icon_url: arrival_icon_url
      }
    }
  end

  def duration
    (route&.fetch('duration').to_i / 60.to_f).round
  end

  def distance
    (route&.fetch('distance').to_i / 1000.to_f).round(1)
  end

  def broadcast_pending_placement
    broadcast_replace_to [mission.daily_quest.company, :steps],
                         target: "mission_step_#{id}",
                         partial: 'daily_quests/step',
                         locals: {
                           pending_placement: true,
                           current_user: nil
                         }
  end

  def broadcast_remove_from_unassigned_bucket
    broadcast_remove_to [mission.daily_quest.company, :steps],
                        target: "mission_step_#{id}"
  end

  def achieved?
    daily_quest.started_on == Date.current && arrival_at <= Time.current
  end

  private

  def daily_quest
    mission.daily_quest
  end

  def options
    @options ||= mission.daily_quest.company.setting.options
  end
end

# == Schema Information
#
# Table name: steps
#
#  id                   :bigint(8)        not null, primary key
#  title                :string
#  started_at           :datetime
#  arrival_at           :datetime
#  departure_point_icon :integer          default(0), not null
#  arrival_point_icon   :integer          default(0), not null
#  role                 :integer          default(0), not null
#  route                :json             not null
#  transporter_id       :bigint(8)
#  mission_id           :bigint(8)        not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  status               :integer          default(0), not null
#
# Indexes
#
#  index_steps_on_mission_id      (mission_id)
#  index_steps_on_transporter_id  (transporter_id)
#
