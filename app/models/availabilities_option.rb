class AvailabilitiesOption
  include StoreModel::Model

  MORNING_START = 7
  MORNING_END = 14
  AFTERNOON_START = 13
  AFTERNOON_END = 20

  AVAILABILITIES = [
    [I18n.t('no_work', scope: i18n_scope), :no_work],
    [I18n.t('morning', scope: i18n_scope), :morning],
    [I18n.t('afternoon', scope: i18n_scope), :afternoon],
    [I18n.t('all_day', scope: i18n_scope), :all_day]
  ].freeze

  PERIODS = {
    no_work: [0, 0],
    morning: [MORNING_START, MORNING_END],
    afternoon: [AFTERNOON_START, AFTERNOON_END],
    all_day: [MORNING_START, AFTERNOON_END]
  }.freeze

  attribute :monday, :string
  attribute :tuesday, :string
  attribute :wednesday, :string
  attribute :thursday, :string
  attribute :friday, :string
  attribute :saturday, :string
  attribute :sunday, :string

  private

  def i18n_scope
    'activemodel'
  end
end
