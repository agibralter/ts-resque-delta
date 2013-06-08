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

    context 'when an index is locked' do
      before do
        ThinkingSphinx::Deltas::ResqueDelta.stub :locked? => true
      end

      it "should not execute the internal job" do
        job.should_not_receive :perform

        subject.perform 'foo_delta'
      end
    end
  end

  describe '.around_perform_lock1' do
    before :each do
      Resque.stub(:encode => 'DeltaJobsAreAwesome')
      Resque.stub_chain(:redis, :lrem)
    end

    it 'should clear all other delta jobs' do
      Resque.redis.should_receive(:lrem).with("queue:#{subject.instance_variable_get(:@queue)}", 0, 'DeltaJobsAreAwesome')

      subject.around_perform_lock1('foo_delta') {}
    end
  end

  describe '.lock_failed' do
    it 'should enqueue the delta job again' do
      Resque.stub(:enqueue => true)
      Resque.should_receive(:enqueue)

      subject.lock_failed('foo_delta')
    end
  end
end
