# Pluralization rule for Simplified Chinese.
#
# rails-i18n ships a rule for `zh-CN`, but the application exposes the language
# as `:zh` and the gem only loads the locale files matching
# `config.i18n.available_locales`. Without a rule the i18n backend falls back to
# the default one/other rule and, with `raise_on_missing_translations` enabled
# (the test environment), every pluralized lookup raises
# `translation missing: zh.i18n.plural.rule` instead.
#
# Chinese has a single plural form, so every count maps to :other. This is a
# Ruby locale file: i18n evaluates it and merges the hash it returns, exactly
# like rails-i18n's own rails/pluralization/zh-CN.rb.
require 'rails_i18n/common_pluralizations/other'

RailsI18n::Pluralization::Other.with_locale(:zh)
