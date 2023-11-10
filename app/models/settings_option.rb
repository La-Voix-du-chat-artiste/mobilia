class SettingsOption
  include StoreModel::Model

  REFRESH_INTERVAL = [30, 60, 90, 120].freeze # in seconds
  THEMES = %w[light dark].freeze

  attribute :map_refresh_interval, :integer, default: -> { REFRESH_INTERVAL[0] }
  attribute :map_gesture_handling, :boolean, default: true
  attribute :theme, :string, default: -> { THEMES[1] }
  attribute :delta_jam, :integer, default: 8
  attribute :delta_loading, :integer, default: 5
  attribute :enable_customers_map, :boolean, default: true
  attribute :enable_places_map, :boolean, default: true
  attribute :enable_transporters_map, :boolean, default: true
  attribute :show_help, :boolean, default: true
  attribute :big_screen_planning_show_all_transporters, :boolean, default: false
  attribute :transporters_can_see_each_others, :boolean, default: true

  attribute :validate_phone_for_customers, :boolean, default: false
  attribute :validate_phone_for_places, :boolean, default: false
  attribute :validate_phone_for_transporters, :boolean, default: false

  attribute :enable_customer_photo, :boolean, default: true
  attribute :enable_place_photo, :boolean, default: true
  attribute :enable_transporter_photo, :boolean, default: true
  attribute :enable_vehicle_photo, :boolean, default: true

  validates :map_refresh_interval, presence: true, inclusion: REFRESH_INTERVAL
  validates :map_gesture_handling, allow_blank: false, inclusion: [true, false]
  validates :theme, presence: true, inclusion: THEMES
  validates :delta_jam, presence: true,
                        numericality: {
                          greater_than_or_equal_to: 0
                        }

  validates :delta_loading, presence: true,
                            numericality: {
                              greater_than_or_equal_to: 0
                            }

  validates :enable_customers_map, allow_blank: false, inclusion: [true, false]
  validates :enable_places_map, allow_blank: false, inclusion: [true, false]
  validates :enable_transporters_map, allow_blank: false, inclusion: [true, false]
  validates :show_help, allow_blank: false, inclusion: [true, false]
  validates :big_screen_planning_show_all_transporters, allow_blank: false, inclusion: [true, false]
  validates :transporters_can_see_each_others, allow_blank: false, inclusion: [true, false]

  validates :validate_phone_for_customers, allow_blank: false, inclusion: [true, false]
  validates :validate_phone_for_places, allow_blank: false, inclusion: [true, false]
  validates :validate_phone_for_transporters, allow_blank: false, inclusion: [true, false]

  validates :enable_customer_photo, allow_blank: false, inclusion: [true, false]
  validates :enable_place_photo, allow_blank: false, inclusion: [true, false]
  validates :enable_transporter_photo, allow_blank: false, inclusion: [true, false]
  validates :enable_vehicle_photo, allow_blank: false, inclusion: [true, false]
end
