module SettingsHelper
  def settings_theme_select_options
    SettingsOption::THEMES.map do |theme|
      [t(theme), theme]
    end
  end
end
