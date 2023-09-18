Geocoder.configure(
  lookup: :ban_data_gouv_fr,
  timeout: 15,
  cache: Redis.new,
  cache_options: {
    expiration: 7.days # Defaults to `nil`
  }
)
