# Simplified Chinese framework strings for the :zh locale.
#
# Rails i18n ships Simplified Chinese as `zh-CN`, and the application exposes
# the language as `:zh`. The app runs without locale fallbacks, so every key
# Rails looks up (dates, times, numbers, validation messages) has to exist for
# :zh — this task derives them from the gem's `zh-CN` data instead of
# maintaining a copy by hand.
#
#   bin/rails i18n:zh_framework
#
# The generated file carries a header explaining where it comes from; the
# application's own zh keys live in the other config/locales/zh*.yml files.
namespace :i18n do
  desc 'Regenerate config/locales/zh.framework.yml from rails-i18n\'s zh-CN data'
  task zh_framework: :environment do
    require 'yaml'

    gem_dir = Gem::Specification.find_by_name('rails-i18n').gem_dir
    source = YAML.load_file(File.join(gem_dir, 'rails/locale/zh-CN.yml')).fetch('zh-CN')

    copied = {}
    %w[activerecord date datetime errors number support time].each do |key|
      copied[key] = source.fetch(key)
    end
    # Our own helpers.submit translations win over the gem's, so only `select`
    # is carried over.
    copied['helpers'] = { 'select' => source.fetch('helpers').fetch('select') }

    header = <<~COMMENT
      # Simplified Chinese framework strings (dates, times, numbers, validation
      # messages) for the :zh locale.
      #
      # Generated from the rails-i18n gem's `zh-CN` data by
      # `bin/rails i18n:zh_framework`; do not edit by hand. The application's own
      # zh keys live in the other config/locales/zh*.yml files.
      #
      # Data derived from rails-i18n (MIT licensed),
      # https://github.com/svenfuchs/rails-i18n
    COMMENT

    path = Rails.root.join('config/locales/zh.framework.yml')
    File.write(path, header + { 'zh' => copied }.to_yaml.delete_prefix("---\n"))
    puts "wrote #{path.relative_path_from(Rails.root)} (#{copied.keys.size} top-level keys)"
  end
end
