module SettingsHelper
  def highlight_code(json)
    json.gsub(',"', ",\n\"")
        .gsub('{', "{\n")
        .gsub('}', "\n}")
        .gsub('":', '": ')
  end

  def settings_theme_select_options
    SettingsOption::THEMES.map do |theme|
      [t(theme), theme]
    end
  end
end
