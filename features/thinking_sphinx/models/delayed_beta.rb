class DelayedBeta < ActiveRecord::Base
  define_index do
    indexes :name, :sortable => true
    set_property :delta => ThinkingSphinx::Deltas::ResqueDelta
  end
end
