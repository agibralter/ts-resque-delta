class FlyingSphinx::ResqueDelta::DeltaJob < ThinkingSphinx::Deltas::ResqueDelta::DeltaJob
  @queue = :fs_delta

  # Runs Sphinx's indexer tool to process the index. Currently assumes Sphinx
  # is running.
  #
  # @param [String] index the name of the Sphinx index
  #
  def self.perform(indices)
    return if skip?(indices)

    FlyingSphinx::IndexRequest.new([indices]).perform
  end
end
