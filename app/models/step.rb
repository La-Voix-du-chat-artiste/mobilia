class Step < ApplicationRecord
  include ActionView::Helpers::AssetUrlHelper
  include Rails.application.routes.url_helpers

  enum role: {
    transporter_to_customer: 0,
    customer_to_place: 1,
    place_to_customer: 2,
    customer_to_transporter: 3,
    customer_to_customer: 4,
    conflict: 5,
    impossible: 6
  }
  enum departure_point_icon: {
    starting_line: 0, transporter: 1, customer: 2, place: 3, ending_line: 4
  }, _prefix: true
  enum arrival_point_icon: {
    starting_line: 0, transporter: 1, customer: 2, place: 3, ending_line: 4
  }, _prefix: true

  belongs_to :transporter, optional: true
  belongs_to :mission

  has_many :addresses, class_name: 'Address', as: :addressable, dependent: :destroy

  has_rich_text :description

  # scope :by_position, -> { order(:position) }
  default_scope -> { order(:started_at) }
  scope :single, -> { where.missing(:transporter) }

  before_save :generate_route, if: ->(step) { step.route.blank? }
  # before_save :set_role, if: ->(step) { step.route.present? }

  # validates :title, presence: true

  def self.routing(departure_address:, arrival_address:, overview: 'false', geometries: 'polyline')
    coords_string = "#{departure_address.longitude},#{departure_address.latitude};#{arrival_address.longitude},#{arrival_address.latitude}"

    resp = Faraday.get("https://router.project-osrm.org/route/v1/driving/#{coords_string}?overview=#{overview}&steps=#{!overview.nil?}&geometries=#{geometries}&alternatives=false")
    json = JSON.parse(resp.body)

    route = json['routes'].first

    route['roads'] = route.fetch('legs').first&.fetch('steps')&.map { |st| st.fetch('name') }&.select(&:present?)&.compact&.uniq

    route.slice('distance', 'duration', 'geometry', 'roads')
  end

  def self.routing_match(addresses)
    all_coords = addresses.map(&:coords)

    stringify_coords = all_coords.map { |c| c.join(',') }.join(';')

    trip_params = "#{stringify_coords}?source=first&destination=last&geometries=polyline&steps=true&roundtrip=false&overview=full"
    Rails.logger.debug { "http://router.project-osrm.org/trip/v1/driving/#{trip_params}" }
    resp = Faraday.get("http://router.project-osrm.org/trip/v1/driving/#{trip_params}")
    json = JSON.parse(resp.body)
    route = json['trips'].first
    route['roads'] = route.fetch('legs').first&.fetch('steps')&.map { |st| st.fetch('name') }&.select(&:present?)&.compact&.uniq

    route['waypoints_index'] = json['waypoints'].pluck('waypoint_index')
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

  def set_role
    daily_step_ids = mission.daily_quest.missions.map(&:step_ids).flatten
    # .where(transporter_id: transporter_id )
    Step.where(id: (daily_step_ids - [id]))
    Address.where(latitude: departure_address.latitude, longitude: departure_address.longitude).ids
    arrival_address_ids = Address.where(latitude: arrival_address.latitude, longitude: arrival_address.longitude).ids

    # same_origin = Step.where(started_at: started_at).where(addresses: Address.where(id: departure_address_ids))
    # arrival_addresses = same_origin.map(&:arrival_addresses)
    # routing_match_from_origin = Step.routing_match(arrival_address)

    same_destination = Step.where(arrival_at: arrival_at).where(addresses: Address.where(id: arrival_address_ids))
    departure_addresses = [Place.first.address] + same_destination.map(&:departure_address) + [arrival_address]
    routing_match_from_destination = Step.routing_match(departure_addresses)

    return if routing_match_from_destination.blank?

    Rails.logger.debug same_destination.map(&:title)

    waypoints_index = routing_match_from_destination.fetch('waypoints_index')

    Rails.logger.debug waypoints_index
    sorted_same_destination = []

    same_destination.each_with_index do |dest, i_dest|
      sorted_same_destination[waypoints_index[i_dest + 1] - 1] = dest
    end

    sorted_same_destination.each_with_index do |dest, i_dest|
      end_point_name = i_dest + 1 == sorted_same_destination.count ? dest.mission.place.name : sorted_same_destination[i_dest + 1].mission.customer.full_name
      dest.title = [dest.mission.customer.full_name, end_point_name].join(' >> ')
    end
  end

  def broadcast_pending_placement
    broadcast_replace_to :steps,
                         target: "mission_step_#{id}",
                         partial: 'daily_quests/step',
                         locals: { pending_placement: true }
  end

  def broadcast_remove_from_unassigned_bucket
    broadcast_remove_to :steps,
                        target: "mission_step_#{id}"
  end

  private

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
#  departure_point_icon :integer          default("starting_line"), not null
#  arrival_point_icon   :integer          default("starting_line"), not null
#  role                 :integer          default("transporter_to_customer"), not null
#  route                :json             not null
#  transporter_id       :bigint(8)
#  mission_id           :bigint(8)        not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_steps_on_mission_id      (mission_id)
#  index_steps_on_transporter_id  (transporter_id)
#
