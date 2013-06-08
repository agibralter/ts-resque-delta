ThinkingSphinx::Index.define :book, :with => :active_record, :delta => ThinkingSphinx::Deltas::ResqueDelta do
  indexes title, author
end if ThinkingSphinx::Index.respond_to?(:define)
