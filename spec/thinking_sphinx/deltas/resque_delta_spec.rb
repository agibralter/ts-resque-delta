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
end
