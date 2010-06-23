Before do
  $queries_executed = []
  ThinkingSphinx::Deltas::ResqueDelta.cancel_thinking_sphinx_jobs
  @model      = nil
  @method     = :search
  @query      = ""
  @conditions = {}
  @with       = {}
  @without    = {}
  @with_all   = {}
  @options    = {}
  @results    = nil
end

Given "Sphinx is running" do
  ThinkingSphinx::Configuration.instance.controller.should be_running
end

Given /^I am searching on (.+)$/ do |model|
  @model = model.gsub(/\s/, '_').singularize.camelize.constantize
end

Given "I have data and it has been indexed" do
  DelayedBeta.create(:name => "one")
  DelayedBeta.create(:name => "two")
  DelayedBeta.create(:name => "three")
  DelayedBeta.create(:name => "four")
  DelayedBeta.create(:name => "five")
  DelayedBeta.create(:name => "six")
  DelayedBeta.create(:name => "seven")
  DelayedBeta.create(:name => "eight")
  DelayedBeta.create(:name => "nine")
  DelayedBeta.create(:name => "ten")
  ThinkingSphinx::Deltas::ResqueDelta.cancel_thinking_sphinx_jobs
  ThinkingSphinx::Configuration.instance.controller.index
  sleep(1.5)
end

When "I wait for Sphinx to catch up" do
  sleep(0.5)
end

When /^I search for (\w+)$/ do |query|
  @results = nil
  @query = query
end

Then /^I should get (\d+) results?$/ do |count|
  results.length.should == count.to_i
end

def results
  @results ||= (@model || ThinkingSphinx).send(
    @method,
    @query,
    @options.merge(
      :conditions => @conditions,
      :with       => @with,
      :without    => @without,
      :with_all   => @with_all
    )
  )
end
