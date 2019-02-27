# frozen_string_literal: true

RSpec.describe BusinessPipeline::Context do
  describe '.build' do
    it 'returns a new instance of the described class' do
      expect(described_class.build).to be_a(described_class)
    end

    context 'when the given argument is an instance of the described class' do
      it 'returns it' do
        previous_context = described_class.new

        expect(described_class.build(previous_context)).to be previous_context
      end
    end

    context 'when the given argument is a Hash' do
      it 'returns a new instance of the described class initialized with it' do
        new_context = described_class.build(name: 'Irvin')

        expect(new_context.name).to eq 'Irvin'
      end
    end
  end

  describe '#fail' do
    it 'sets its failure to true' do
      subject.fail

      expect(subject).to be_failure
    end
  end

  describe '#fail!' do
    it 'updates the context with the given Hash' do
      catch(:early_stop) { subject.fail!(name: 'Irvin') }

      expect(subject.name).to eq 'Irvin'
    end

    it 'sets its failure to true' do
      catch(:early_stop) { subject.fail! }

      expect(subject).to be_failure
    end

    it 'throws an early stop' do
      expect { subject.fail! }.to throw_symbol(:early_stop)
    end
  end

  describe '#failure?' do
    it 'returns true if context is failed' do
      subject.fail

      expect(subject.failure?).to be true
    end

    it 'returns false if context is not failed' do
      expect(subject.failure?).to be false
    end
  end

  describe '#succeed!' do
    it 'updates the context with the given Hash' do
      catch(:early_stop) { subject.succeed!(name: 'Irvin') }

      expect(subject.name).to eq 'Irvin'
    end

    it 'throws an early stop' do
      expect { subject.succeed! }.to throw_symbol(:early_stop)
    end
  end

  describe '#success?' do
    it 'returns false if context is failed' do
      subject.fail
      expect(subject.success?).to be false
    end

    it 'returns true if context is not failed' do
      expect(subject.success?).to be true
    end
  end
end
