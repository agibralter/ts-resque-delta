require 'resque-loner'
# A simple job for flagging a specified Sphinx document in a given index as
# 'deleted'.
#  
class ThinkingSphinx::Deltas::ResqueDelta::FlagAsDeletedJob

  include Resque::Plugins::UniqueJob
  @queue = :ts_delta

  # Takes an index name and document id. Please note that the document id is
  # Sphinx's unique identifier, and will almost certainly not be the model
  # instance's primary key value. Updates the sphinx_deleted attribute for the
  # given document, setting the value to 1 (true). This is not a special
  # attribute in Sphinx, but is used by Thinking Sphinx to ignore deleted
  # values between full re-indexing. It's particularly useful in this
  # situation to avoid old values in the core index and just use the new
  # values in the delta index as a reference point.
  #
  # @param [Array] indexes An array of index names
  # @param [Integer] document_id The document id
  #
  # @return [Boolean] true
  #
  def self.perform(indexes, document_id)
    config = ThinkingSphinx::Configuration.instance
    indexes.each do |index|
      if ThinkingSphinx.sphinx_running? && ThinkingSphinx.search_for_id(document_id, index)
        config.client.update(index, ['sphinx_deleted'], {document_id => [1]})
      end
    end
  end
end
