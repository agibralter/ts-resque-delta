require 'spec_helper'

describe ThinkingSphinx::Deltas::ResqueDelta::IndexUtils do
  let(:indices) { %w[foo_core foo_delta foo bar_core bar_delta bar] }
  let(:config) { double('config') }

  before :each do
    ThinkingSphinx::Configuration.stub(:instance => config)
    config.stub(:generate)
    config.stub_chain(:configuration, :indices, :collect => indices)

    subject.reload!
  end

  describe '.index_prefixes' do
    it 'should use a cached value if one exists' do
      indices = []
      subject.instance_variable_set(:@prefixes, indices)

      subject.index_prefixes.should be(indices)
    end

    it 'should return a list of only index prefixes' do
      subject.index_prefixes.should =~ %w[foo bar]
    end
  end

  describe '.core_indices' do
    it 'should use a cached value if one exists' do
      indices = []
      subject.instance_variable_set(:@core_indices, indices)

      subject.core_indices.should be(indices)
    end

    it 'should return a list of only core indices' do
      subject.core_indices.should =~ %w[foo_core bar_core]
    end
  end

  describe '.delta_indices' do
    it 'should use a cached value if one exists' do
      indices = []
      subject.instance_variable_set(:@delta_indices, indices)

      subject.delta_indices.should be(indices)
    end

    it 'should return a list of only delta indices' do
      subject.delta_indices.should =~ %w[foo_delta bar_delta]
    end
  end

  describe '.ts_config' do
    it 'should use a cached value if one exists' do
      subject.instance_variable_set(:@ts_config, config)

      subject.ts_config.should be(config)
    end

    it 'should generate the config when fetching the Configuration instance' do
      config.should_receive(:generate)

      subject.ts_config
    end
  end
end
