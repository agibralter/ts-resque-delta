require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::CoreIndex do
  let(:indices) { %w[foo bar] }
  let(:config) { double('config') }

  describe '#lock_delta' do
    it 'should lock the delta' do
      ThinkingSphinx::Deltas::ResqueDelta.should_receive(:lock)

      subject.lock_delta('foo')
    end

    it 'should lock the delta for the given index' do
      ThinkingSphinx::Deltas::ResqueDelta.should_receive(:lock).with('foo_delta')

      subject.lock_delta('foo')
    end
  end

  describe '#unlock_delta' do
    it 'should unlock the delta' do
      ThinkingSphinx::Deltas::ResqueDelta.should_receive(:unlock)

      subject.unlock_delta('foo')
    end

    it 'should unlock the delta for the given index' do
      ThinkingSphinx::Deltas::ResqueDelta.should_receive(:unlock).with('foo_delta')

      subject.unlock_delta('foo')
    end
  end

  describe '#lock_deltas' do
    it 'should lock all delta indices' do
      subject.stub(:sphinx_indices => indices)

      indices.each {|index| subject.should_receive(:lock_delta).once.with(index) }

      subject.lock_deltas
    end
  end

  describe '#unlock_deltas' do
    it 'should unlock all delta indices' do
      subject.stub(:sphinx_indices => indices)

      indices.each {|index| subject.should_receive(:unlock_delta).once.with(index) }

      subject.unlock_deltas
    end
  end

  describe '#with_delta_index_lock' do
    before :each do
      subject.stub(:lock_delta)
      subject.stub(:unlock_delta)

      subject.stub(:block_called)

      @block_called = false
      @block = lambda { @block_called = true; subject.block_called }
    end

    it 'should yield' do
      subject.with_delta_index_lock('foo', &@block)
      @block_called.should be_true
    end

    it 'should lock before yielding' do
      subject.should_receive(:lock_delta).with('foo').ordered
      subject.should_receive(:block_called).ordered

      subject.with_delta_index_lock('foo', &@block)
    end

    it 'should unlock after yielding' do
      subject.should_receive(:block_called).ordered
      subject.should_receive(:unlock_delta).with('foo').ordered

      subject.with_delta_index_lock('foo', &@block)
    end
  end

  describe '#smart_index' do
    include FakeFS::SpecHelpers

    let(:test_path) { '/tmp/ts-resque-delta/foo' }

    before :each do
      subject.stub(:ts_config => config)
      config.stub(:config_file => 'foo_config')
      config.stub(:build)
      config.stub(:searchd_file_path => test_path)
      config.stub_chain(:controller, :index) do
        # Set $? to 0
        `/usr/bin/true`
      end

      # Silence Generating config message
      subject.stub(:puts)

      subject.stub(:index_prefixes => indices)
      subject.stub(:lock_delta)
      subject.stub(:unlock_delta)

      ThinkingSphinx::Deltas::ResqueDelta.stub(:prepare_for_core_index)
      Resque.stub(:enqueue)
    end

    it 'should not generate sphinx configuration if INDEX_ONLY is true' do
      ENV.stub(:[]).with('INDEX_ONLY').and_return('true')
      ENV.stub(:[]).with('SILENT').and_return(nil)
      config.should_not_receive(:build)

      subject.smart_index
    end

    it 'should generate sphinx configuration if INDEX_ONLY is not true' do
      ENV.stub(:[]).with('INDEX_ONLY').and_return(nil)
      ENV.stub(:[]).with('SILENT').and_return(nil)
      config.should_receive(:build).once

      subject.smart_index
    end

    it 'should create the sphinx file directory' do
      subject.smart_index

      File.directory?(test_path).should be_true
    end

    it 'should index all core indices' do
      indices.each do |index|
        config.controller.should_receive(:index).with("#{index}_core", anything)
      end

      subject.smart_index
    end

    context "with delta lock" do
      before :each do
        subject.stub(:with_delta_index_lock).and_yield
      end

      it 'should index' do
        config.controller.should_receive(:index)
        subject.smart_index
      end

      it 'should signal resque delta to prepare for the core index' do
        ThinkingSphinx::Deltas::ResqueDelta.should_receive(:prepare_for_core_index)
        subject.smart_index
      end
    end

    context "without delta lock" do
      before :each do
        subject.stub(:with_delta_index_lock)
      end

      it 'should not index without the delta lock' do
        config.controller.should_not_receive(:index)
        subject.smart_index
      end

      it 'should not signal resque delta to prepare for the core index' do
        ThinkingSphinx::Deltas::ResqueDelta.should_not_receive(:prepare_for_core_index)
        subject.smart_index
      end
    end

    it 'should create a delta job after the delta is unlocked' do
      # Create a dummy method on subject that's called when Resque.enqueue is called so we can enforce order.
      subject.stub(:resque_called)
      Resque.stub(:enqueue) { subject.resque_called }

      Resque.should_receive(:enqueue)

      subject.should_receive(:with_delta_index_lock).ordered.exactly(indices.size)
      subject.should_receive(:resque_called).ordered.exactly(indices.size)

      subject.smart_index
    end

    context 'with an error' do
      before :each do
        config.stub_chain(:controller, :index) do
          # Set $? to 1
          `/usr/bin/false`
        end
      end

      it 'should stop processing indexes after an error' do
        config.controller.should_receive(:index).once

        subject.smart_index
      end

      it 'should return false on failure' do
        subject.smart_index.should be_false
      end
    end

    it 'should return true on success' do
      subject.smart_index.should be_true
    end
  end
end
