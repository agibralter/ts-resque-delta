require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::DeltaJob do
  subject do
    ThinkingSphinx::Deltas::ResqueDelta::DeltaJob
  end

  describe '.perform' do
    let(:job) { double 'Job', :perform => true }

    before :each do
      ThinkingSphinx::Deltas::ResqueDelta.stub :locked? => false
      ThinkingSphinx::Deltas::IndexJob.stub :new => job
    end

    it "sets up the internal Thinking Sphinx job with the provided index" do
      ThinkingSphinx::Deltas::IndexJob.should_receive(:new).with('foo_delta').
        and_return(job)

      subject.perform 'foo_delta'
    end

    it "should execute the internal job" do
      job.should_receive :perform

      subject.perform 'foo_delta'
    end
  end
end
