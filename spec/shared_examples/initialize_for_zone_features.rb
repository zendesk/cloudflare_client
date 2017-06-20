shared_examples 'initialize for zone features' do
  describe '#initialize' do
    it 'returns a CloudflareClient::Zone::Analytics instance' do
      expect { subject }.to_not raise_error
      expect(subject).to be_a(described_class)
    end

    context 'when zone_id is missing' do
      let(:valid_zone_id) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, 'zone_id required')
      end
    end
  end
end
