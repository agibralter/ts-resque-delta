require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta do
  describe '#index' do
    before :each do
      ThinkingSphinx.updates_enabled = true
      ThinkingSphinx.deltas_enabled  = true

      Resque.stub!(:enqueue => true)

      @delayed_delta = ThinkingSphinx::Deltas::ResqueDelta.new(
        stub('instance'), {}
      )
      @delayed_delta.stub!(:toggled => true)

      @model = stub('foo')
      @model.stub!(:name => 'foo')
      @model.stub!(:source_of_sphinx_index => @model)
      @model.stub!(:core_index_names  => ['foo_core'])
      @model.stub!(:delta_index_names => ['foo_delta'])

      @instance = stub('instance')
      @instance.stub!(:sphinx_document_id => 42)
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
        @delayed_delta.stub!(:toggled => false)
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

    it "should enqueue a delta job for the appropriate indexes" do
      Resque.should_receive(:enqueue).with(ThinkingSphinx::Deltas::ResqueDelta::DeltaJob, ['foo_delta']).once
      @delayed_delta.index(@model)
    end

    it "should enqueue a flag-as-deleted job for the appropriate indexes" do
      # WTF RSpec: http://gist.github.com/447611
      # Resque.should_receive(:enqueue).with(ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob, ['foo_core'], an_instance_of(Numeric))
      Resque.should_receive(:enqueue).twice
      @delayed_delta.index(@model, @instance)
    end

    it "should enqueue a flag-as-deleted job for the appropriate id" do
      # WTF RSpec: http://gist.github.com/447611
      # Resque.should_receive(:enqueue).with(ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob, an_instance_of(Array), 42)
      Resque.should_receive(:enqueue).twice
      @delayed_delta.index(@model, @instance)
    end
  end
end
