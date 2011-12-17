require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet do
  describe '.add' do
    before :each do
      Resque.stub_chain(:redis, :sadd => true)
    end

    it 'should add the document id to the correct set' do
      Resque.redis.should_receive(:sadd).once.with(subject.set_name('foo_core'), 42)
      subject.add('foo_core', 42)
    end
  end

  describe '.clear!' do
    before :each do
      Resque.stub_chain(:redis, :del)
      ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.stub(:around_perform_lock)
    end

    it 'should delete all items in the set' do
      Resque.redis.should_receive(:del).once.with(subject.set_name('foo_core'))
      subject.clear!('foo_core')
    end

    context "with DeltaJob integration" do
      before :each do
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.stub(:around_perform_lock).and_yield
      end

      it 'should acquire the DeltaJob lock' do
        ThinkingSphinx::Deltas::ResqueDelta::DeltaJob.should_receive(:around_perform_lock).once.with('foo_delta')
        subject.clear!('foo_core')
      end

      it 'should delete all items in the processing set' do
        Resque.redis.should_receive(:del).once.with(subject.processing_name('foo_core'))
        subject.clear!('foo_core')
      end
    end
  end

  describe '.clear_all!' do
    let(:core_indices) { %w[foo_core bar_core] }

    it 'should clear each index' do
      ThinkingSphinx::Deltas::ResqueDelta::IndexUtils.stub_chain(:core_indices, :each).tap do |s|
        core_indices.inject(s) do |s, index|
          s.and_yield(index)
        end
      end

      core_indices.each do |index|
        subject.should_receive(:clear!).with(index)
      end

      subject.clear_all!
    end
  end

  describe '.get_subset_for_processing' do
    let(:mock_redis) do
      Resque.redis = mr = MockRedis.new
      subject.add 'foo_core', 42
      subject.add 'foo_core', 52
      subject.add 'foo_core', 100
      mr
    end

    before :each do
      Resque.redis = mock_redis.clone
    end

    it 'should move all members from the flag as deleted set to the processing set' do
      subject.get_subset_for_processing('foo_core')

      Resque.redis.scard(subject.set_name('foo_core')).should eql(0)
      Resque.redis.scard(subject.processing_name('foo_core')).should eql(3)
    end

    it 'should remove the temp set' do
      subject.get_subset_for_processing('foo_core')

      Resque.redis.scard(subject.temp_name('foo_core')).should eql(0)
    end

    it 'should preserve existing members of the processing set' do
      Resque.redis.sadd(subject.processing_name('foo_core'), 1)

      subject.get_subset_for_processing('foo_core')

      Resque.redis.smembers(subject.processing_name('foo_core')).should =~ %w[1 42 52 100]
    end
  end

  describe '.processing_members' do
    let(:document_ids) { %w[1, 2, 3] }

    before :each do
      Resque.stub_chain(:redis, :smembers => document_ids)
    end

    it 'should get the members of the correct set' do
      Resque.redis.should_receive(:smembers).once.with(subject.processing_name('foo_core'))
      subject.processing_members('foo_core')
    end

    it 'should return a list of integers' do
      subject.processing_members('foo_core').each do |id|
        id.class.should == Fixnum
      end
    end
  end

  describe '.clear_processing' do
    before :each do
      Resque.stub_chain(:redis, :del)
    end

    it 'should delete the processing set' do
      Resque.redis.should_receive(:del).once.with(subject.processing_name('foo_core'))

      subject.clear_processing('foo_core')
    end
  end
end
