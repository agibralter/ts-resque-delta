# A simple job class that processes a given index.
# 
class ThinkingSphinx::Deltas::ResqueDelta::DeltaJob

  @queue = :ts_delta

  # Runs Sphinx's indexer tool to process the index. Currently assumes Sphinx
  # is running.
  # 
  # @param [String] index the name of the Sphinx index
  # 
  def self.perform(indexes)
    config = ThinkingSphinx::Configuration.instance
    output = `#{config.bin_path}#{config.indexer_binary_name} --config #{config.config_file} --rotate #{indexes.join(' ')}`
    puts output unless ThinkingSphinx.suppress_delta_output?
  end
end
