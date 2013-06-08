class ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob
  @queue = :ts_delta

  def self.perform(index, document_id)
    ThinkingSphinx::Deltas::DeleteJob.new(index, document_id).perform
  end
end
