require 'rails_helper'
require 'yaml'

# Structural checks on the locale files themselves.
#
# Nothing else in the suite would notice a key that only exists in French, a
# placeholder dropped while translating, a file whose root key does not match
# its name, or a value that YAML parsed as a number instead of a string — and
# with no locale fallbacks those all turn into a broken page for someone.
RSpec.describe 'Locale files' do
  # zh.framework.yml is generated from rails-i18n's zh-CN data and holds only
  # framework strings that the gems already ship for :fr and :en, so it cannot be
  # compared key by key with them.
  def app_files
    @app_files ||= Rails.root.glob('config/locales/*.yml')
                        .reject { |file| file.to_s.end_with?('zh.framework.yml') }
  end

  def leaf_keys(tree, prefix = [])
    return [prefix.join('.')] unless tree.is_a?(Hash)

    tree.flat_map { |key, value| leaf_keys(value, prefix + [key.to_s]) }
  end

  def app_tree(locale)
    app_files.flat_map do |file|
      tree = YAML.load_file(file)[locale.to_s]
      leaf_keys(tree || {}).map { |key| [key, tree.dig(*key.split('.'))] }
    end.to_h
  end

  describe 'the files' do
    it 'roots each one at the locale its name announces' do
      app_files.each do |file|
        announced = File.basename(file).split('.')[-2]

        expect(YAML.load_file(file).keys).to eq([announced]),
                                             "#{File.basename(file)} should be rooted at #{announced}"
      end
    end

    it 'parses to a tree of non-empty strings' do
      app_files.each do |file|
        tree = YAML.load_file(file).values.first
        values = leaf_keys(tree || {}).map { |key| tree.dig(*key.split('.')) }

        expect(values).to all(be_a(String)), file.to_s
        expect(values).to all(satisfy { |value| !value.strip.empty? }), file.to_s
      end
    end
  end

  describe 'the three languages' do
    it 'define exactly the same keys' do
      reference = app_tree(:fr)

      %i[en zh].each do |locale|
        keys = app_tree(locale).keys
        extra = keys - reference.keys
        missing = reference.keys - keys

        expect(extra).to be_empty, "#{locale} defines keys French does not: #{extra.first(10)}"
        expect(missing).to be_empty, "#{locale} is missing: #{missing.first(10)}"
      end
    end

    it 'keep the same interpolation variables' do
      reference = app_tree(:fr)

      %i[en zh].each do |locale|
        app_tree(locale).each do |key, value|
          expected = reference[key].to_s.scan(/%\{(\w+)\}/).flatten.sort

          expect(value.to_s.scan(/%\{(\w+)\}/).flatten.sort).to eq(expected),
                                                                "#{locale}.#{key} has different %{} variables than French"
        end
      end
    end
  end

  describe 'Simplified Chinese framework strings' do
    # Rails i18n ships them as zh-CN and the app exposes :zh, so they live in a
    # generated file. These few are the ones a page cannot render without.
    it 'covers the framework namespaces the app renders' do
      expect(I18n.t('date.day_names', locale: :zh)).to include('星期一')
      expect(I18n.t('errors.messages.blank', locale: :zh)).to be_present
      expect(I18n.t('number.format.separator', locale: :zh)).to be_present
      expect(I18n.t('support.array.words_connector', locale: :zh)).to be_present
      expect(I18n.l(Date.new(2026, 9, 14), format: :complete_slash, locale: :zh)).to include('年')
    end

    # rails-i18n ships this rule for `zh-CN` only, and a pluralized lookup
    # without one raises as soon as missing translations raise (see
    # config/locales/zh.pluralization.rb).
    it 'has a pluralization rule' do
      rule = I18n.t('i18n.plural.rule', locale: :zh, resolve: false)

      expect(rule).to respond_to(:call)
      expect([0, 1, 7].map { |count| rule.call(count) }).to all(eq(:other))
    end
  end
end
