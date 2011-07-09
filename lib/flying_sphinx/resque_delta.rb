class FlyingSphinx::ResqueDelta < ThinkingSphinx::Deltas::ResqueDelta
  def self.job_types
    [
      FlyingSphinx::ResqueDelta::DeltaJob,
      FlyingSphinx::ResqueDelta::FlagAsDeletedJob
    ]
  end
  
  def self.job_prefix
    'fs-delta'
  end
  
  def index(model, instance = nil)
    return true if skip?(instance)
    
    model.delta_index_names.each do |delta|
      next if self.class.locked?(delta)
      
      Resque.enqueue(
        FlyingSphinx::ResqueDelta::DeltaJob,
        [delta]
      )
    end
    
    Resque.enqueue(
      FlyingSphinx::ResqueDelta::FlagAsDeletedJob,
      model.core_index_names,
      instance.sphinx_document_id
    ) if instance
    
    true
  end
end

require 'flying_sphinx/resque_delta/delta_job'
require 'flying_sphinx/resque_delta/flag_as_deleted_job'
