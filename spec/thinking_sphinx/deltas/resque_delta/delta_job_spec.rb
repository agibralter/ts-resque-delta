require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::DeltaJob do
  subject do
    ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.tap do |s|
      s.stub(:` => true)
      s.stub(:puts => nil)
    end
  end

  describe '.perform' do
    before :each do
      ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?).and_return(false)
      ThinkingSphinx.stub(:sphinx_running? => false)
    end

    context 'when an index is locked' do
      before do
        ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?) do |index_name|
          index_name == 'foo_delta' ? true : false
        end
      end

      it "should not start the indexer" do
        subject.should_not_receive(:`)
        subject.perform('foo_delta')
      end

      it "should start the indexer for unlocked indexes" do
        subject.should_receive(:`)
        subject.perform('bar_delta')
      end
    end
  end

  describe '.around_perform_lock1' do
    before :each do
      Resque.stub(:encode => 'DeltaJobsAreAwesome')
      Resque.stub_chain(:redis, :lrem)
      ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet.stub(:get_subset_for_processing)
      ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet.stub(:clear_processing)
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
