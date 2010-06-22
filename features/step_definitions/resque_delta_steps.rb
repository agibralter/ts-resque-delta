When /^I run the delayed jobs$/ do
  unless @resque_worker
    @resque_worker = Resque::Worker.new("ts_delta")
    @resque_worker.register_worker
  end
  while job = @resque_worker.reserve
    @resque_worker.perform(job)
  end
end

When /^I change the name of delayed beta (\w+) to (\w+)$/ do |current, replacement|
  DelayedBeta.find_by_name(current).update_attributes(:name => replacement)
end
