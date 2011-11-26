When /^I run the delayed jobs$/ do
  unless @resque_worker
    @resque_worker = Resque::Worker.new("ts_delta")
    @resque_worker.register_worker
  end
  while job = @resque_worker.reserve
    @resque_worker.perform(job)
  end
end

When /^I run one delayed job$/ do
  unless @resque_worker
    @resque_worker = Resque::Worker.new("ts_delta")
    @resque_worker.register_worker
  end
  job = @resque_worker.reserve
  @resque_worker.perform(job)
end

When /^I cancel the jobs$/ do
  ThinkingSphinx::Deltas::ResqueDelta.clear!
end

When /^I change the name of delayed beta (\w+) to (\w+)$/ do |current, replacement|
  DelayedBeta.find_by_name(current).update_attributes(:name => replacement)
end

Then /^there should be no more DeltaJobs on the Resque queue$/ do
  job_classes = Resque.redis.lrange("queue:ts_delta", 0, -1).collect do |j|
    Resque.decode(j)["class"]
  end
  job_classes.should_not include("ThinkingSphinx::Deltas::ResqueDelta::DeltaJob")
end
