Feature: Resque Delta Indexing
  In order to have delta indexing on frequently-updated sites
  Developers
  Should be able to use Resque to handle delta indices to lower system load

  Background:
    Given Sphinx is running
    And I am searching on delayed betas
    And I have data and it has been indexed

  Scenario: Delta Index should not fire automatically
    When I search for one
    Then I should get 1 result

    When I change the name of delayed beta one to eleven
    And I wait for Sphinx to catch up
    And I search for one
    Then I should get 1 result

    When I search for eleven
    Then I should get 0 results

  Scenario: Delta Index should fire when jobs are run
    When I search for one
    Then I should get 1 result

    When I change the name of delayed beta two to twelve
    And I wait for Sphinx to catch up
    And I search for twelve
    Then I should get 0 results

    When I run the delayed jobs
    And I wait for Sphinx to catch up
    And I search for twelve
    Then I should get 1 result

    When I search for two
    Then I should get 0 results

  Scenario: ensuring that duplicate jobs are deleted
    When I change the name of delayed beta two to fifty
    And I change the name of delayed beta five to twelve
    And I change the name of delayed beta one to fifteen
    And I change the name of delayed beta six to twenty
    And I run one delayed job
    Then there should be no more DeltaJobs on the Resque queue

    When I run the delayed jobs
    And I wait for Sphinx to catch up
    And I search for fifty
    Then I should get 1 result

    When I search for two
    Then I should get 0 results

  Scenario: canceling jobs
    When I change the name of delayed beta two to fifty
    And I cancel the jobs
    And I run the delayed jobs
    And I wait for Sphinx to catch up
    And I search for fifty
    Then I should get 0 results
