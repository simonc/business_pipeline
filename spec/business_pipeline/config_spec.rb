RSpec.describe BusinessPipeline::Config do
  describe '#initialize' do
    it 'expects no argument' do
      expect { described_class.new }.not_to raise_exception
    end

    it 'accepts an initial hash' do
      config = described_class.new(name: 'Irvin')

      expect(config.name).to eq 'Irvin'
    end

    it 'accepts an empty hash' do
      expect { described_class.new({}) }.not_to raise_exception
    end

    it 'evals the provided block' do
      config = described_class.new do
        name 'Irvin'
      end

      expect(config.name).to eq 'Irvin'
    end
  end

  describe '#fetch' do
    it 'returns the value of a given key' do
      subject.name = 'Irvin'

      expect(subject.fetch(:name)).to eq 'Irvin'
    end

    it 'requires a key' do
      expect { subject.fetch }.to raise_exception(ArgumentError)
    end

    context 'when the value for the key is nil' do
      context 'and a block is provided' do
        it 'yields the key to the given block' do
          expect { |b| subject.fetch(:name, &b) }.to yield_with_args(:name)
        end
      end

      context 'and no block is provided' do
        it 'raises an exception' do
          expect { subject.fetch(:name) }.to raise_exception(KeyError, 'name')
        end
      end
    end
  end

  describe 'DSL setter' do
    context 'when calling an unknown method with an argument' do
      it 'stores its value with the given key' do
        subject.name 'Irvin'
        expect(subject.name).to eq 'Irvin'
      end
    end
  end
end
