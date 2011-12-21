Feature: Smart Indexing
  In order to have core indexing that works well with resque delta indexing
  Developers
  Should be able to use smart index to update core indices

  Background:
    Given Sphinx is running
    And I am searching on delayed betas
    And I have data

  Scenario: Smart indexing should update core indices
    When I run the smart indexer
    And I wait for Sphinx to catch up
    And I search for one
    Then I should get 1 result

  Scenario: Smart indexing should reset the delta index
    Given I have indexed
    When I change the name of delayed beta one to eleven
    And I run the delayed jobs
    And I wait for Sphinx to catch up

    When I change the name of delayed beta eleven to one
    And I run the smart indexer
    And I run the delayed jobs
    And I wait for Sphinx to catch up

    When I search for eleven
    Then I should get 0 results

  Scenario: Delta Index running after smart indexing should not hide records
    When I run the smart indexer
    And I run the delayed jobs
    And I wait for Sphinx to catch up

    When I search for two
    Then I should get 1 result

  Scenario: Smart index should remove existing delta jobs
    When I run the smart indexer
    And I run one delayed job
    And I wait for Sphinx to catch up
    Then there should be no more DeltaJobs on the Resque queue
