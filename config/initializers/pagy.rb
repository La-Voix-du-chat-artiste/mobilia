require 'pagy/extras/array'
require 'pagy/extras/i18n'
require 'pagy/extras/overflow'

# pagy 9 renamed and retyped both of these, and neither mistake is visible until a
# list has more than one page:
#
#   * `:items` became `:limit`. Leaving the old name meant the setting was
#     silently ignored and every list paginated at pagy's default of 20.
#   * `:size` became an Integer (the number of page links) instead of an array of
#     slots. The array form is only validated inside the nav helper, so it booted
#     fine and then raised Pagy::VariableError on the first paginated screen
#     (`expected :size to be an Integer >= 0; got [1, 1, 1, 1]`).
Pagy::DEFAULT[:limit] = 10
Pagy::DEFAULT[:size] = 5
Pagy::DEFAULT[:overflow] = :last_page
