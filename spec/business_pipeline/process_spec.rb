RSpec.describe BusinessPipeline::Process do
  subject { Class.new { include BusinessPipeline::Process } }

  let(:step1) do
    Class.new do
      include BusinessPipeline::Step
      def call; end
    end
  end
  let(:step2) do
    Class.new do
      include BusinessPipeline::Step
      def call; end
    end
  end

  let(:failing_step) do
    Class.new do
      include BusinessPipeline::Step
      def call; context.fail!; end
    end
  end

  describe '.step' do
    it 'adds a step to the list of steps' do
      subject.step step1

      expect(subject.steps).to eq [[step1, nil]]
    end

    it 'accepts a block to customize the Step’s config' do
      subject.step(step1) {}

      expect(subject.steps).to match [[step1, Proc]]
    end
  end

  describe '.steps' do
    it 'returns the list of Steps in the order they were added with their config block' do
      subject.step(step1)
      subject.step(step2) {}

      expect(subject.steps).to match [[step1, nil], [step2, Proc]]
    end

    context 'when no Step was added' do
      it 'returns an empty collection' do
        expect(subject.steps).to eq []
      end
    end
  end

  describe '#call' do
    let(:step1) { double(new: step1_instance) }
    let(:step2) { double(new: step2_instance) }
    let(:step1_instance) { spy }
    let(:step2_instance) { spy }

    it 'executes each step in the defined order' do
      subject.step step1
      subject.step step2

      subject.new.call

      expect(step1_instance).to have_received(:perform).ordered
      expect(step2_instance).to have_received(:perform).ordered
    end

    context 'when a step was initialized with a block' do
      it 'initializes the step with the given block' do
        block_content = spy
        subject.step(step1) { block_content.call }

        subject.new.call

        expect(block_content).to have_received(:call)
      end
    end
  end

  describe '#perform' do
    let(:config_inspector_step) do
      Class.new do
        include BusinessPipeline::Step
        def call
          context.config_processes = config._processes
        end
      end
    end

    it 'adds itself the list of _processes in config before calling its steps' do
      subject.step config_inspector_step
      result = subject.new.perform

      expect(result.config_processes).to eq []
    end

    context 'when the process is not called by another process' do
      let(:step1) { failing_step }

      it 'handles early stops' do
        subject.step step1
        process = subject.new

        expect { process.perform }.not_to throw_symbol
      end
    end

    context 'when the process is called by another process' do
      let(:step1) { failing_step }

      it 'does not handle early stops' do
        subject.step step1
        process = subject.new(_processes: [:test])

        expect { process.perform }.to throw_symbol
      end
    end
  end
end
