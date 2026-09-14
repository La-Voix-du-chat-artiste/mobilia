# frozen_string_literal: true

# Two uniqueness constraints were global when they should be per tenant.
#
# * vehicles.number_plate had a global unique index, so two companies could not
#   both register the same plate. The model validation is now scoped by
#   company_id, so the index has to follow.
# * settings are meant to be one-per-company (Setting#confirm_singularity! tried
#   to enforce that in a callback that never actually fired). A unique index is
#   the enforcement point that cannot be bypassed.
class ScopeUniqueIndexesToCompany < ActiveRecord::Migration[8.1]
  def up
    remove_index :vehicles, :number_plate, if_exists: true
    add_index :vehicles, %i[company_id number_plate], unique: true, if_not_exists: true

    # The stock settings index is named index_settings_on_company_id, which is
    # exactly the name add_index would derive for the unique index too. With
    # `if_not_exists: true` Rails then matched the existing non-unique index by
    # name and silently skipped creating it, so the constraint was never
    # enforced. Drop it first, then add the unique one.
    remove_index :settings, :company_id, if_exists: true
    add_index :settings, :company_id, unique: true
  end

  def down
    remove_index :vehicles, %i[company_id number_plate], if_exists: true
    add_index :vehicles, :number_plate, unique: true, if_not_exists: true

    remove_index :settings, :company_id, if_exists: true
    add_index :settings, :company_id
  end
end
