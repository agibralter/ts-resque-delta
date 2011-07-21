require 'spec_helper'

describe FlyingSphinx::ResqueDelta::FlagAsDeletedJob do
  describe '@queue' do
    it "uses the fs_delta queue" do
      FlyingSphinx::ResqueDelta::FlagAsDeletedJob.
        instance_variable_get(:@queue).should == :fs_delta
    end
  end
  
  describe '.perform' do
    it "performs a flag-as-deleted job" do
      job = double('flag as deleted job', :perform => true)
      
      FlyingSphinx::FlagAsDeletedJob.should_receive(:new).
        with(['foo_core'], 5).
        and_return(job)
      job.should_receive(:perform)
      
      FlyingSphinx::ResqueDelta::FlagAsDeletedJob.perform ['foo_core'], 5
    end
  end
end
