module MissionsHelper
  def value_for_drop_duration_hours(mission)
    return mission.drop_duration_hours if mission.new_record?

    mission.drop_duration / 60
  end

  def value_for_drop_duration_minutes(mission)
    return mission.drop_duration_minutes if mission.new_record?

    mission.drop_duration % 60
  end
end
