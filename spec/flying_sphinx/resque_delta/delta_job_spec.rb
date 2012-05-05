require 'spec_helper'

describe FlyingSphinx::ResqueDelta::DeltaJob do
  describe '@queue' do
    it "uses the fs_delta queue" do
      FlyingSphinx::ResqueDelta::DeltaJob.instance_variable_get(:@queue).
        should == :fs_delta
    end
  end

  describe '.perform' do
    it "doesn't create an index request when skipping" do
      FlyingSphinx::ResqueDelta::DeltaJob.stub!(:skip? => true)

      FlyingSphinx::IndexRequest.should_not_receive(:new)

      FlyingSphinx::ResqueDelta::DeltaJob.perform 'foo_delta'
    end

    it "performs an index request when not skipping" do
      request = double('index request', :perform => true)
      FlyingSphinx::ResqueDelta::DeltaJob.stub!(:skip? => false)

      FlyingSphinx::IndexRequest.should_receive(:new).
        with(['foo_delta']).
        and_return(request)
      request.should_receive(:perform)

      FlyingSphinx::ResqueDelta::DeltaJob.perform 'foo_delta'
    end
  end
end
