RSpec.describe BusinessPipeline::Step do
  subject do
    Class.new do
      include BusinessPipeline::Step
      def call; context.step_config = config; end
    end
  end

  describe '#initialize' do
    it 'accepts a config of type Hash' do
      expect { subject.new(name: 'Irvin') }.not_to raise_exception
    end

    it 'accepts a config of type Config' do
      config = BusinessPipeline::Config.new(name: 'Irvin')

      expect { subject.new(config) }.not_to raise_exception
    end
  end

  describe '#call' do
    subject do
      Class.new { include BusinessPipeline::Step }
    end

    it 'raises an exception' do
      expect { subject.new.call }.to raise_exception(NotImplementedError)
    end
  end

  describe '#fail!' do
    subject do
      Class.new do
        include BusinessPipeline::Step
        def call; fail!(name: 'Irvin'); end
      end
    end

    let(:context_spy) { spy }

    before { allow(BusinessPipeline::Context).to receive(:build).and_return(context_spy) }

    it 'fails the context and passes it the additional context' do
      subject.new.perform

      expect(context_spy).to have_received(:fail!).with(name: 'Irvin')
    end
  end

  describe '#perform' do
    subject do
      Class.new do
        include BusinessPipeline::Step
        before { |context| context.hooks_ran = true }
        def call; context.step_ran = true; end
      end
    end

    it 'sets up the execution context and returns it at the end' do
      result = subject.new.perform(name: 'Irvin')

      expect(result.name).to eq 'Irvin'
    end

    it 'runs the hooks' do
      result = subject.new.perform

      expect(result.hooks_ran).to be true
    end

    it 'runs the #call method' do
      result = subject.new.perform

      expect(result.step_ran).to be true
    end
  end

  describe '#succeed!' do
    subject do
      Class.new do
        include BusinessPipeline::Step
        def call; succeed!(name: 'Irvin'); end
      end
    end

    let(:context_spy) { spy }

    before { allow(BusinessPipeline::Context).to receive(:build).and_return(context_spy) }

    it 'succeeds the context and passes it the additional context' do
      subject.new.perform

      expect(context_spy).to have_received(:succeed!).with(name: 'Irvin')
    end
  end

  describe 'hooks inheritence' do
    context 'when a class inherits a Step' do
      subject do
        Class.new do
          include BusinessPipeline::Step
          before { |context| context.hooks_ran = true }
          def call; end
        end
      end

      let(:step) { Class.new(subject) }

      it 'inherits its hooks' do
        result = step.new.perform

        expect(result.hooks_ran).to be true
      end
    end
  end
end
