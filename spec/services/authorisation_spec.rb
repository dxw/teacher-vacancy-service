require 'rails_helper'
RSpec.describe Authorisation do
  describe '.new' do
    it 'requires an organisation_id and user_id' do
      result = described_class.new(
        organisation_id: '123', user_id: '456'
      )

      expect(result).to be_kind_of(described_class)
    end
  end

  describe '#call' do
    subject do
      described_class.new(
        organisation_id: '939eac36-0777-48c2-9c2c-b87c948a9ee0',
        user_id: '161d1f6a-44f1-4a1a-940d-d1088c439da7'
      )
    end

    before(:each) do
      stub_authorisation_step
    end

    it 'stores the role_ids' do
      result = subject.call
      expect(result.role_ids).to eq(['test-role-id'])
    end

    it 'configure SSL to be used for this request' do
      expect(Net::HTTP).to receive(:start)
        .with(anything, anything, use_ssl: true)
        .and_return(double(code: '200', body: '{ "roles": [] }'))

      subject.call
    end

    it 'sets the request headers for authorisation and content' do
      jwt_token = double
      expect(JWT).to receive(:encode).with(
        {
          iss: 'schooljobs',
          exp: (Time.now.getlocal + 60).to_i,
          aud: 'signin.education.gov.uk'
        },
        'test-password',
        'HS256'
      ).and_return(jwt_token)

      request_double = double(Net::HTTP::Get)
      expect(Net::HTTP::Get).to receive(:new).and_return(request_double)
      expect(request_double).to receive(:[]=).with('Content-Type', 'application/json')
      expect(request_double).to receive(:[]=).with('Authorization', "bearer #{jwt_token}")

      expect_any_instance_of(Net::HTTP).to receive(:request)
        .with(request_double)
        .and_return(double(code: '200', body: '{ "roles": [] }'))

      subject.call
    end
  end

  describe '#authorised?' do
    subject do
      described_class.new(
        organisation_id: '123',
        user_id: '456',
      )
    end

    context 'when roles include a known role_id' do
      it 'returns true' do
        subject.role_ids = ['test-role-id']
        expect(subject.authorised?).to be true
      end
    end

    context 'when roles do not include a known role_id' do
      it 'returns true' do
        subject.role_ids = ['unknown-role-id']
        expect(subject.authorised?).to be false
      end
    end

    context 'when there are no roles' do
      it 'returns false' do
        subject.role_ids = []
        expect(subject.authorised?).to be false
      end
    end
  end
end
