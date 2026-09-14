require 'rails_helper'
require 'yaml'

# What the app asks for, versus what the locale files define.
#
# The rendering spec proves that the pages reachable by a test account translate
# cleanly; this one is static and therefore catches keys on the paths no spec
# visits, plus translations nobody uses any more.
RSpec.describe 'Translations' do
  # `t('key')`, `t "key"`, `I18n.t('key')`, `translate('key')`, with or without
  # parentheses. `\b` keeps `format(`/`link_to(` out.
  def key_call
    /\b(?:I18n\.)?(?:t|translate)\s*\(?\s*['"]([\w.-]+)['"]/
  end

  # Namespaces whose every key is written literally at the call site, which makes
  # "defined but never used" a reliable signal. The other namespaces are looked up
  # by libraries (simple_form, the framework) or built dynamically (seo, pagy).
  def literal_namespaces
    %w[views. common. flash.]
  end

  def source_files
    Rails.root.glob('app/**/*.{rb,slim,erb}') +
      Rails.root.glob('lib/**/*.rb') +
      Rails.root.glob('spec/**/*.rb')
  end

  def used_keys
    source_files.flat_map { |file| File.read(file).scan(key_call).flatten }
                # Dynamic keys (`t("views.#{x}.title")`) and the `scope:` form
                # (`t('title', scope: :seo)`) are not literal keys.
                .reject { |key| key.include?('#{') || key.exclude?('.') }
                .uniq
  end

  def flatten(tree, prefix = [])
    return [prefix.join('.')] unless tree.is_a?(Hash)

    tree.flat_map { |key, value| flatten(value, prefix + [key.to_s]) }
  end

  def defined_keys
    Rails.root.glob('config/locales/*.yml').flat_map do |file|
      tree = YAML.load_file(file).values.first
      tree ? flatten(tree) : []
    end.uniq
  end

  it 'defines every literal key the app uses, in all three languages' do
    missing = used_keys.reject do |key|
      I18n.available_locales.all? { |locale| I18n.exists?(key, locale) }
    end.sort

    expect(missing).to be_empty, "keys used but not translated: #{missing.first(20)}"
  end

  it 'has no unused string translation' do
    defined = defined_keys
    unused = literal_namespaces.flat_map { |prefix| defined.select { |key| key.start_with?(prefix) } } - used_keys

    expect(unused).to be_empty, "translations nobody uses: #{unused.first(20)}"
  end
end
