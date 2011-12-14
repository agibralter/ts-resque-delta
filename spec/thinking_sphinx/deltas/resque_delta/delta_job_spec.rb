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
      ThinkingSphinx.suppress_delta_output = false
      ThinkingSphinx::Deltas::ResqueDelta.stub(:locked?).and_return(false)
    end

    it "should output the delta indexing by default" do
      subject.should_receive(:puts)
      subject.perform('foo_delta')
    end

    it "should not output the delta indexing if requested" do
      ThinkingSphinx.suppress_delta_output = true
      subject.should_not_receive(:puts)
      subject.perform('foo_delta')
    end

    it "should process just the requested index" do
      subject.should_receive(:`) do |c|
        c.should match(/foo_delta/)
        c.should_not match(/--all/)
      end
      subject.perform('foo_delta')
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

    context 'with flag as deleted document ids' do
      let(:client) { stub('client', :update => true) }
      let(:document_ids) { [1, 2, 3] }
      let(:bundled_search) { double('bundled_search', :search_for_ids => []) }

      before :each do
        ThinkingSphinx.updates_enabled = true

        ThinkingSphinx::Configuration.instance.stub(:client => client)
        ThinkingSphinx.stub(:sphinx_running? => true)

        ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet.stub(:processing_members => document_ids)
        ThinkingSphinx::Search.stub_chain(:bundle_searches, :map => document_ids)
      end

      it 'should get the processing set of flag as deleted document ids' do
        ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet.should_receive(:processing_members).with('foo_core')
        subject.perform('foo_delta')
      end

      it "should not update if Sphinx isn't running" do
        ThinkingSphinx.stub(:sphinx_running? => false)
        client.should_not_receive(:update)
        subject.perform('foo_delta')
      end

      it "should validate the document ids with sphinx" do
        ThinkingSphinx::Search.stub(:bundle_searches).tap do |s|
          document_ids.inject(s) do |s, id|
            s.and_yield(bundled_search, id)
          end
        end

        document_ids.each do |id|
          bundled_search.should_receive(:search_for_ids).with([], :index => 'foo_core', :id_range => id..id)
        end

        subject.perform('foo_delta')
      end

      context "with invalid ids" do
        before :each do
          ThinkingSphinx::Search.stub_chain(:bundle_searches, :map => document_ids.reject {|x| x == 2} )
        end

        it "should not update documents that aren't in the index" do
          client.should_receive(:update) do |index, attributes, values|
            values.should_not include(2)
          end
          subject.perform('foo_delta')
        end

        it "should update documents that are in the index" do
          client.should_receive(:update) do |index, attributes, values|
            values.keys.should eql(document_ids.reject{|x| x == 2})
          end
          subject.perform('foo_delta')
        end
      end

      it "should update the specified index" do
        client.should_receive(:update) do |index, attributes, values|
          index.should == 'foo_core'
        end
        subject.perform('foo_delta')
      end

      it "should update the sphinx_deleted attribute" do
        client.should_receive(:update) do |index, attributes, values|
          attributes.should == ['sphinx_deleted']
        end
        subject.perform('foo_delta')
      end

      it "should set sphinx_deleted for valid documents to true" do
        client.should_receive(:update) do |index, attributes, values|
          document_ids.each {|id| values[id].should == [1] }
        end
        subject.perform('foo_delta')
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

    it 'should set up the processing set of document ids' do
      ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet.should_receive(:get_subset_for_processing).with('foo_core')

      subject.around_perform_lock1('foo_delta') {}
    end

    it 'should clear the processing set when finished' do
      ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedSet.should_receive(:clear_processing).with('foo_core')

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
