shared_examples 'initialize for zone firewall waf package features' do
  describe '#initialize' do
    it 'returns a client instance' do
      expect { subject }.to_not raise_error
      expect(subject).to be_a(described_class)
    end

    context 'when zone_id is missing' do
      let(:zone_id) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, 'zone_id required')
      end
    end

    context 'when package_id is missing' do
      let(:package_id) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, 'package_id required')
      end
    end
  end
end
