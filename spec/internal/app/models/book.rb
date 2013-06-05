class Book < ActiveRecord::Base
  define_index do
    indexes title, author

    set_property :delta => ThinkingSphinx::Deltas::ResqueDelta
  end if respond_to?(:define_index)
end
