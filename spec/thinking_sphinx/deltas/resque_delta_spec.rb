require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta do
  before :each do
    Resque.redis = MockRedis.new
  end

  describe '.cancel_jobs' do
    subject { ThinkingSphinx::Deltas::ResqueDelta.cancel_jobs }

    before :all do
      class RandomJob
        @queue = 'ts_delta'
      end
    end

    before :each do
      Resque.enqueue(ThinkingSphinx::Deltas::ResqueDelta::DeltaJob, 'foo_delta')
      Resque.enqueue(ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob, 'bar_delta')
      Resque.enqueue(RandomJob, '1234')
    end

    it 'should remove all jobs' do
      subject
      Resque.size('ts_delta').should eq(0)
    end
  end

  describe '.lock' do
    it 'should set the lock key in redis' do
      ThinkingSphinx::Deltas::ResqueDelta.lock('foo')
      Resque.redis.get("#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:index:foo:locked").should eql('true')
    end
  end

  describe '.unlock' do
    it 'should unset the lock key in redis' do
      Resque.redis.set("#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:index:foo:locked", 'true')
      ThinkingSphinx::Deltas::ResqueDelta.unlock('foo')
      Resque.redis.get("#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:index:foo:locked").should be_nil
    end
  end

  describe '.locked?' do
    subject { ThinkingSphinx::Deltas::ResqueDelta.locked?('foo') }

    context "when lock key in redis is true" do
      before { Resque.redis.set("#{ThinkingSphinx::Deltas::ResqueDelta.job_prefix}:index:foo:locked", 'true') }
      it { should be_true }
    end

    context "when lock key in redis is nil" do
      it { should be_false }
    end
  end
end
