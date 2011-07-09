class FlyingSphinx::ResqueDelta::FlagAsDeletedJob
  @queue = :ts_delta
  
  def self.perform(indices, document_id)
    FlyingSphinx::FlagAsDeletedJob.new(indices, document_id).perform
  end
end
