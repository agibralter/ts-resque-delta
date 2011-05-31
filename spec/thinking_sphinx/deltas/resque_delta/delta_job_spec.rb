require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::DeltaJob do
  describe '.perform' do
    before :each do
      ThinkingSphinx.suppress_delta_output = false
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.stub(:` => true)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.stub(:puts => nil)
      ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?).and_return(false)
    end

    it "should output the delta indexing by default" do
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:puts)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(
        ['foo_delta']
      )
    end

    it "should not output the delta indexing if requested" do
      ThinkingSphinx.suppress_delta_output = true
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_not_receive(:puts)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(
        ['foo_delta']
      )
    end

    it "should process just the requested indexes" do
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:`) do |c|
        c.should match(/foo_delta/)
        c.should_not match(/--all/)
      end
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(
        ['foo_delta']
      )
    end

    context 'multiple indexes' do
      it "should process all requested indexes" do
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:`) do |c|
          c.should match(/foo_delta bar_delta/)
        end
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(
          ['foo_delta', 'bar_delta']
        )
      end
    end

    context 'when an index is locked' do
      before do
        ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?) do |index_name|
          index_name == 'foo_delta' ? true : false
        end
      end

      it "should not start the indexer" do
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_not_receive(:`)
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(
          ['foo_delta']
        )
      end

      it "should not start the indexer for multiple indexes" do
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_not_receive(:`)
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(
          ['bar_delta', 'foo_delta']
        )
      end
    end
  end
end
