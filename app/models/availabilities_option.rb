class AvailabilitiesOption
  include StoreModel::Model

  AVAILABILITIES = [
    [I18n.t('no_work', scope: i18n_scope), :no_work],
    [I18n.t('morning', scope: i18n_scope), :morning],
    [I18n.t('afternoon', scope: i18n_scope), :afternoon],
    [I18n.t('all_day', scope: i18n_scope), :all_day]
  ].freeze

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
