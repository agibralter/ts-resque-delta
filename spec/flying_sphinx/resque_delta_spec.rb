require 'spec_helper'

describe FlyingSphinx::ResqueDelta do
  describe '.job_types' do
    it "contains just the Flying Sphinx delta and delete jobs" do
      FlyingSphinx::ResqueDelta.job_types.should == [
        FlyingSphinx::ResqueDelta::DeltaJob,
        FlyingSphinx::ResqueDelta::FlagAsDeletedJob
      ]
    end
  end
  
  describe '.job_prefix' do
    it "is fs-delta" do
      FlyingSphinx::ResqueDelta.job_prefix.should == 'fs-delta'
    end
  end
  
  describe '#index' do
    before :each do
      ThinkingSphinx.updates_enabled = true
      ThinkingSphinx.deltas_enabled  = true

      Resque.stub(:enqueue => true)

      @delayed_delta = FlyingSphinx::ResqueDelta.new(
        stub('instance'), {}
      )
      @delayed_delta.stub(:toggled).and_return(true)

      FlyingSphinx::ResqueDelta.stub(:lock)
      FlyingSphinx::ResqueDelta.stub(:unlock)
      FlyingSphinx::ResqueDelta.stub(:locked?).and_return(false)

      @model = stub('foo')
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
        FlyingSphinx::ResqueDelta::DeltaJob,
        ['foo_delta']
      )
      @delayed_delta.index(@model)
    end

    it "should enqueue a flag-as-deleted job" do
      Resque.should_receive(:enqueue).at_least(:once).with(
        FlyingSphinx::ResqueDelta::FlagAsDeletedJob,
        ['foo_core'],
        42
      )
      @delayed_delta.index(@model, @instance)
    end

    context "delta index is locked" do
      before :each do
        FlyingSphinx::ResqueDelta.stub(:locked?).and_return(true)
      end

      it "should not enqueue a delta job" do
        Resque.should_not_receive(:enqueue).with(
          FlyingSphinx::ResqueDelta::DeltaJob,
          ['foo_delta']
        )
        @delayed_delta.index(@model, @instance)
      end

      it "should enqueue a flag-as-deleted job" do
        Resque.should_receive(:enqueue).at_least(:once).with(
          FlyingSphinx::ResqueDelta::FlagAsDeletedJob,
          ['foo_core'],
          42
        )
        @delayed_delta.index(@model, @instance)
      end
    end
  end
end
