require 'rails_helper'

RSpec.describe Company do
  it 'creates its Setting' do
    company = create(:company)

    expect(company.setting).to be_persisted
    expect(company.setting.options).to be_a(SettingsOption)
    expect(company.setting.options.theme).to eq('dark')
  end
end

RSpec.describe Setting do
  let(:company) { create(:company) }

  it 'round-trips options through the json column' do
    company.setting.update!(options: { theme: 'light', delta_jam: 12, map_gesture_handling: false })

    reloaded = described_class.find(company.setting.id)
    expect(reloaded.options.theme).to eq('light')
    expect(reloaded.options.delta_jam).to eq(12)
    expect(reloaded.options.map_gesture_handling).to be(false)
    # untouched keys keep their defaults
    expect(reloaded.options.show_help).to be(true)
  end

  # The old guard read Setting.find_by(id: company.id) — it looked the setting up
  # by its own id, so it never fired and a company could accumulate settings.
  it 'refuses a second setting for the same company' do
    duplicate = described_class.new(company: company)

    expect(duplicate.save).to be(false)
    expect(duplicate.errors[:company_id]).to be_present
    expect(described_class.where(company_id: company.id).count).to eq(1)
  end

  it 'is enforced by a unique index, not only by the validation' do
    index = ActiveRecord::Base.connection.indexes(:settings).find { |i| i.columns == %w[company_id] }

    expect(index).to be_present
    expect(index.unique).to be(true)
  end
end
