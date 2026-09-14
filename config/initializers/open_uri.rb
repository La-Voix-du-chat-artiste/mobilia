# `URI.open` (used to fetch the generated avatar images) lives in the standard
# library, which is not autoloaded. Renamed from the misleading `support.rb`.
require 'open-uri'
