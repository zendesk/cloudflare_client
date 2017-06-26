shared_examples 'initialize for organization features' do
  describe '#initialize' do
    it 'returns a client instance' do
      expect { subject }.to_not raise_error
      expect(subject).to be_a(described_class)
    end

    context 'when org_id is missing' do
      let(:org_id) { nil }

      it 'raises error' do
        expect { subject }.to raise_error(StandardError, 'org_id required')
      end
    end
  end
end
