# The lookup builds its URL from Geocoder's `protocol`, which is "http" unless
# use_https is set, and the BAN endpoint (data.geopf.fr since geocoder 1.8.6)
# does not answer on port 80. Without this, every lookup waits out the timeout
# and then returns nothing — so addresses silently end up with no coordinates,
# and every mission generated from them fails to route.
Geocoder.configure(use_https: true)

if Rails.env.test?
  # Geocoder ships a :test lookup driven by explicit stubs, so specs never reach
  # the BAN API (or Redis) and addresses cannot silently end up without
  # coordinates because of a network timeout. Stub results with
  # `Geocoder::Lookup::Test.add_stub` in the specs that need them.
  Geocoder.configure(lookup: :test, cache: nil)
else
  Geocoder.configure(
    lookup: :ban_data_gouv_fr,
    timeout: 15,
    # `Redis.new` used to ignore REDIS_URL entirely and always talk to
    # redis://localhost:6379/0, silently sharing a namespace with the cache and
    # Action Cable.
    cache: Redis.new(url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379/1')),
    cache_prefix: 'geocoder',
    cache_options: {
      expiration: 7.days # Defaults to `nil`
    }
  )
end
