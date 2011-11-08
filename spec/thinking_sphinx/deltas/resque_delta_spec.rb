require 'spec_helper'
require 'mock_redis'

describe ThinkingSphinx::Deltas::ResqueDelta do
  describe '#index' do
    before :each do
      ThinkingSphinx.updates_enabled = true
      ThinkingSphinx.deltas_enabled  = true

      Resque.stub(:enqueue => true)

      @delayed_delta = ThinkingSphinx::Deltas::ResqueDelta.new(
        stub('instance'), {}
      )
      @delayed_delta.stub(:toggled).and_return(true)

      ThinkingSphinx::Deltas::ResqueDelta.stub(:lock)
      ThinkingSphinx::Deltas::ResqueDelta.stub(:unlock)
      ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?).and_return(false)

      @model = stub('foo')
      @model.stub(:name => 'foo')
      @model.stub(:source_of_sphinx_index => @model)
      @model.stub(:core_index_names  => ['foo_core'])
      @model.stub(:delta_index_names => ['foo_delta'])

      @instance = stub('instance')
      @instance.stub(:sphinx_document_id => 42)
    end

    context 'updates disabled' do
      before :each do
        ThinkingSphinx.updates_enabled = false
      end

      it "should not enqueue a delta job" do
        Resque.should_not_receive(:enqueue)
        @delayed_delta.index(@model)
      end

      it "should not enqueue a flag as deleted job" do
        Resque.should_not_receive(:enqueue)
        @delayed_delta.index(@model)
      end
    end

    context 'deltas disabled' do
      before :each do
        ThinkingSphinx.deltas_enabled = false
      end

      it "should not enqueue a delta job" do
        Resque.should_not_receive(:enqueue)
        @delayed_delta.index(@model)
      end

      it "should not enqueue a flag as deleted job" do
        Resque.should_not_receive(:enqueue)
        @delayed_delta.index(@model)
      end
    end

    context "instance isn't toggled" do
      before :each do
        @delayed_delta.stub(:toggled => false)
      end

      it "should not enqueue a delta job" do
        Resque.should_not_receive(:enqueue)
        @delayed_delta.index(@model, @instance)
      end

      it "should not enqueue a flag as deleted job" do
        Resque.should_not_receive(:enqueue)
        @delayed_delta.index(@model, @instance)
      end
    end

    it "should enqueue a delta job" do
      Resque.should_receive(:enqueue).at_least(:once).with(
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
        ['foo_delta']
      )
      @delayed_delta.index(@model)
    end

    it "should enqueue a flag-as-deleted job" do
      Resque.should_receive(:enqueue).at_least(:once).with(
        ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob,
        ['foo_core'],
        42
      )
      @delayed_delta.index(@model, @instance)
    end

    context "delta index is locked" do
      before :each do
        ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?).and_return(true)
      end

      it "should not enqueue a delta job" do
        Resque.should_not_receive(:enqueue).with(
          ThinkingSphinx::Deltas::ResqueDelta::DeltaJob,
          ['foo_delta']
        )
        @delayed_delta.index(@model, @instance)
      end

      it "should enqueue a flag-as-deleted job" do
        Resque.should_receive(:enqueue).at_least(:once).with(
          ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob,
          ['foo_core'],
          42
        )
        @delayed_delta.index(@model, @instance)
      end
    end
  end

  context 'without duplicates' do
    before :all do
      Resque.redis = MockRedis.new
    end

    before :each do
      Resque.redis.flushall
    end

    it "should not enqueue a duplicate delta job" do
      Resque.enqueue ThinkingSphinx::Deltas::ResqueDelta::DeltaJob, ['foo_delta']
      Resque.enqueue ThinkingSphinx::Deltas::ResqueDelta::DeltaJob, ['foo_delta']

      Resque.size(Resque.queue_from_class(ThinkingSphinx::Deltas::ResqueDelta::DeltaJob)).should == 1
    end

    it "should not enqueue a duplicate flag-as-deleted job" do
      Resque.enqueue ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob, ['foo_delta'], 42
      Resque.enqueue ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob, ['foo_delta'], 42

      Resque.size(Resque.queue_from_class(ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob)).should == 1
    end
  end
end
