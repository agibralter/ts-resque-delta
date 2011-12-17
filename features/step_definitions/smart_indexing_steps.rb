When /^I run the smart indexer$/ do
  ThinkingSphinx::Deltas::ResqueDelta::CoreIndex.new.smart_index(:verbose => false)
end
