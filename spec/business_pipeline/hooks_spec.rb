RSpec.describe BusinessPipeline::Hooks do
  subject { Class.new { include BusinessPipeline::Hooks } }

  let(:after_hook) { double }
  let(:around_hook) { double }
  let(:before_hook) { double }

  describe '.add_hooks/.hooks' do
    it 'stores hooks with the right type' do
      subject.add_hooks before_hook, type: :before
      subject.add_hooks after_hook, type: :after
      subject.add_hooks around_hook, type: :around

      expect(subject.hooks).to eq(
        after: [after_hook],
        around: [around_hook],
        before: [before_hook])
    end
  end

  describe '.after' do
    it 'stores a hook as an after hook' do
      subject.after after_hook

      expect(subject.hooks).to include(after: [after_hook])
    end
  end

  describe '.around' do
    it 'stores a hook as an around hook' do
      subject.around around_hook

      expect(subject.hooks).to include(around: [around_hook])
    end
  end

  describe '.before' do
    it 'stores a hook as an before hook' do
      subject.before before_hook

      expect(subject.hooks).to include(before: [before_hook])
    end
  end

  describe 'Hooks usage' do
    subject { subject_class.new }

    let(:subject_class) do
      Class.new do
        include BusinessPipeline::Hooks

        around do |step, context|
          context.count = 1
          step.call
          context.count += 5
        end

        before { |context| context.count += 2 }

        after { |context| context.count += 4 }

        attr_reader :config, :context

        def initialize
          @config = OpenStruct.new
          @context = OpenStruct.new
        end

        def call
          with_hooks { context.count += 3 }
          context.count
        end
      end
    end

    it 'calls all the hooks as expected' do
      expect(subject.call).to eq 15
    end
  end
end
