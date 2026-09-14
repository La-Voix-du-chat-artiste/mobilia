class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  geocoded_by :label do |obj, results|
    result = results.first

    if result.present?
      feature = result.data['features'].first

      properties = feature['properties']
      geo = feature.dig('geometry', 'coordinates')

      if geo && properties
        obj.street = properties['name']
        obj.postcode = properties['postcode']
        obj.town = properties['city']
        obj.country = 'France'
        obj.latitude = geo[1]
        obj.longitude = geo[0]
      end
    end
  end

  after_validation :geocode, if: :label_changed?
  after_validation :warn_when_not_geocoded, if: :label_changed?

  validates :label, presence: true

  def coords
    [longitude, latitude]
  end

  private

  # Geocoding fails silently: on a network error, a rate limit or an address the
  # BAN API does not know, latitude/longitude simply stay blank and the record is
  # saved unusable. The symptom then shows up much later, as a routing error in a
  # background job. At least leave a trace.
  def warn_when_not_geocoded
    return if latitude.present? && longitude.present?

    Rails.logger.warn("[Address] could not geocode #{label.inspect}: latitude/longitude are blank")
  end
end

# == Schema Information
#
# Table name: addresses
#
#  id               :bigint(8)        not null, primary key
#  label            :string
#  street           :string
#  postcode         :string
#  town             :string
#  country          :string
#  latitude         :float
#  longitude        :float
#  addressable_type :string           not null
#  addressable_id   :bigint(8)        not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addresses_on_addressable  (addressable_type,addressable_id)
#
