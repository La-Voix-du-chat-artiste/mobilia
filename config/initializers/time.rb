require 'active_support/core_ext/numeric'

class Time
  def round(seconds = 5.minutes.to_i)
    Time.at((to_f / seconds).round * seconds).utc
  end
end
