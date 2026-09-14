require 'rails_helper'

RSpec.describe Vehicle do
  describe 'number plate uniqueness' do
    it 'rejects a duplicate plate inside the same company' do
      company = create(:company)
      create(:vehicle, company: company, number_plate: 'AB-123-CD')

      duplicate = build(:vehicle, company: company, number_plate: 'AB-123-CD')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number_plate]).to be_present
    end

    # The index used to be global, so two tenants could not both register the
    # same plate.
    it 'allows the same plate in another company' do
      create(:vehicle, company: create(:company), number_plate: 'AB-123-CD')

      expect(build(:vehicle, company: create(:company), number_plate: 'AB-123-CD')).to be_valid
    end

    it 'is enforced by a unique index scoped to the company' do
      index = ActiveRecord::Base.connection.indexes(:vehicles)
                                .find { |i| i.columns == %w[company_id number_plate] }

      expect(index).to be_present
      expect(index.unique).to be(true)
    end

    it 'no longer has a global unique index on the plate' do
      global = ActiveRecord::Base.connection.indexes(:vehicles)
                                 .find { |i| i.columns == %w[number_plate] }

      expect(global).to be_nil
    end
  end

  describe 'breaking down' do
    # Vehicle has_one :transporter, so the foreign key lives on transporters.
    it 'unassigns the transporter that was using the vehicle' do
      transporter = create(:transporter)
      vehicle = create(:vehicle, company: transporter.company, transporter: transporter)

      vehicle.update!(status: :breakdown)

      expect(vehicle.reload.transporter).to be_nil
      expect(transporter.reload.vehicle_id).to be_nil
    end

    it 'leaves the transporter alone for a status change that does not matter' do
      transporter = create(:transporter)
      vehicle = create(:vehicle, company: transporter.company, transporter: transporter)

      vehicle.update!(name: 'Trafic')

      expect(vehicle.reload.transporter).to eq(transporter)
    end
  end
end
