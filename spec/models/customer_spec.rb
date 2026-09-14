require 'rails_helper'

RSpec.describe Customer do
  # Optionable#options reads company.setting, so the company has to be persisted
  # (build(:company) would have no Setting yet).
  let(:company) { create(:company) }

  describe 'email validation' do
    # The old regex capped the TLD at 2-3 characters and used \w for the local
    # part, so these perfectly valid addresses were rejected.
    it 'accepts a +tag and a four-character TLD' do
      expect(build(:customer, company: company, email: 'first+tag@example.museum')).to be_valid
    end

    it 'accepts a dotted local part and a multi-part TLD' do
      expect(build(:customer, company: company, email: 'first.last@example.co.uk')).to be_valid
    end

    it 'rejects an address with no domain' do
      customer = build(:customer, company: company, email: 'nope@')

      expect(customer).not_to be_valid
      expect(customer.errors[:email]).to be_present
    end

    it 'rejects an address with no @' do
      expect(build(:customer, company: company, email: 'nope.example.test')).not_to be_valid
    end

    it 'is still optional' do
      expect(build(:customer, company: company, email: nil)).to be_valid
    end
  end

  describe 'generated avatar' do
    it 'attaches the fetched avatar' do
      customer = create(:customer)

      expect(customer.photo).to be_attached
      # ui-avatars answers the `format=jpg` in the request with PNG, so the stored
      # filename has to follow the response rather than the request.
      expect(customer.photo.filename.to_s).to eq('customer.png')
      expect(customer.photo.blob.content_type).to eq('image/png')
    end

    it 'follows the service when it answers with JPEG instead' do
      stub_avatars!(body: avatar_jpeg_bytes, content_type: 'image/jpeg')

      expect(create(:customer).photo.filename.to_s).to eq('customer.jpg')
    end

    # The fetch used to run unguarded inside after_create, so an unreachable
    # avatar service rolled back the whole record.
    it 'keeps the record when the avatar service is unreachable' do
      stub_avatars_timeout!

      customer = create(:customer)

      expect(customer).to be_persisted
      expect(customer.photo).not_to be_attached
    end

    # The name used to be interpolated into the URL unescaped, so any name with
    # a space or an accent raised URI::InvalidURIError.
    it 'percent-encodes the name in the avatar URL' do
      create(:place, name: 'Clinique Saint-Jean & Cie')

      expect(a_request(:get, /name=Clinique%20Saint-Jean%20%26%20Cie/)).to have_been_made.once
    end

    it 'builds the avatar URL from a literal host' do
      expect(described_class.avatar_url('Ann Onymous', background: '22c55e'))
        .to start_with('https://ui-avatars.com/api/?format=jpg&name=Ann%20Onymous')
    end
  end

  describe '#in_wheelchair?' do
    it 'is true for both wheelchair kinds' do
      expect(build(:customer, kind: :wheelchair)).to be_in_wheelchair
      expect(build(:customer, kind: :wheelchair_auto)).to be_in_wheelchair
      expect(build(:customer, kind: :walker)).not_to be_in_wheelchair
    end
  end
end
