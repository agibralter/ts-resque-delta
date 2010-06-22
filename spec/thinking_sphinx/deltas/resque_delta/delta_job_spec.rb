require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::DeltaJob do
  describe '.perform' do
    before :each do
      ThinkingSphinx.suppress_delta_output = false
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.stub(:` => true)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.stub(:puts => nil)
    end

    it "should output the delta indexing by default" do
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:puts)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(['foo_core'])
    end

    it "should not output the delta indexing if requested" do
      ThinkingSphinx.suppress_delta_output = true
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_not_receive(:puts)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(['foo_core'])
    end

    it "should process just the requested indexes" do
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:`) do |command|
        command.should match(/foo_core/)
        command.should_not match(/--all/)
      end
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(['foo_core'])
    end

    context 'multiple indexes' do
      it "should process all requested indexes" do
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:`) do |command|
          command.should match(/foo_core bar_core/)
        end
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.perform(['foo_core', 'bar_core'])
      end
    end
  end
end
