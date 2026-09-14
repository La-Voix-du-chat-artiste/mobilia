require 'rails_helper'

# Rails 8 removed the `enum name: {...}` keyword form and the `_prefix` /
# `_default` options. Declaring an enum the old way raises ArgumentError the
# moment the model is loaded, but models load lazily — so the app booted, the
# migrations ran, and every enum was broken. Touching the constants is the
# regression test.
RSpec.describe 'enum declarations' do
  enums_by_model = {
    Absence => { reason: %w[unspecified holidays disease other_company attending] },
    Customer => { kind: %w[walker wheelchair wheelchair_auto] },
    DailyQuest => { status: %w[not_started pending ended] },
    Step => {
      role: %w[transporter_to_customer customer_to_place place_to_customer
               customer_to_transporter customer_to_customer],
      status: %w[possible conflict impossible],
      departure_point_icon: %w[starting_line transporter customer place ending_line],
      arrival_point_icon: %w[starting_line transporter customer place ending_line]
    },
    User => { role: %w[standard admin super_admin] },
    Vehicle => { status: %w[normal breakdown mechanic] }
  }

  enums_by_model.each do |model, enums|
    context model.name do
      enums.each do |enum_name, values|
        it "maps #{enum_name} to the expected values" do
          expect(model.defined_enums.fetch(enum_name.to_s).keys).to match_array(values)
        end
      end
    end
  end

  it 'exposes predicates and bang setters for the mapped values' do
    expect(Step.new(status: :conflict)).to be_conflict
    expect(Vehicle.new(status: :breakdown)).to be_breakdown
    expect(Customer.new(kind: :walker)).to be_walker
  end

  it 'applies the declared defaults' do
    expect(Customer.new.kind).to eq('wheelchair')
    expect(DailyQuest.new.status).to eq('not_started')
    expect(User.new.role).to eq('standard')
  end

  it 'prefixes the step icon enums' do
    step = Step.new(departure_point_icon: :place, arrival_point_icon: :customer)

    expect(step.departure_point_icon_place?).to be(true)
    expect(step.arrival_point_icon_customer?).to be(true)
    expect(step.respond_to?(:place?)).to be(false)
  end

  it 'provides the not_<value> scope that Absence.covering relies on' do
    expect(Absence.not_attending.to_sql).to include('!=')
  end
end
