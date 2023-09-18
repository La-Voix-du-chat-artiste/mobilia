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

  validates :label, presence: true

  def coords
    [longitude, latitude]
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
