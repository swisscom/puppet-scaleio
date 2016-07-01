require 'spec_helper'

describe Puppet::Type.type(:scaleio_mdm_cluster).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_mdm_cluster).new(
      {
          :ensure => :present,
          :name => 'mdm_cluster',
          :mdm_names => ['mdm-1', 'mdm-2'],
          :tb_names => ['mdm-3'],
      }
  ) }

  let(:no_mdm) { my_fixture_read('prop_empty.cli') }
  let(:multiple_mdms) { my_fixture_read('prop_mdm_multiple.cli') }


  describe 'basics' do
    properties = []

    it("should have a create method") { expect(provider).to respond_to(:create) }
    it("should have a destroy method") { expect(provider).to respond_to(:destroy) }
    it("should have an exists? method") { expect(provider).to respond_to(:exists?) }
    properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        expect(provider).to respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        expect(provider).to respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    context 'with multiple MDMs' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(multiple_mdms)
        @instances = provider.class.instances
      end
      it 'detects one cluster' do
        names = @instances.collect { |x| x.name }
        expect(%w(mdm_cluster)).to match_array(names)
      end
      it 'with 2 MDMs' do
        expect(@instances[0].mdm_names).to match_array(%w(node1 node2))
      end
      it 'and 1 TB' do
        expect(@instances[0].tb_names).to match_array(%w(node3))
      end
    end

    context 'with no MDM' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(no_mdm)
        @instances = provider.class.instances
      end
      it 'detects one cluster' do
        names = @instances.collect { |x| x.name }
        expect(%w(mdm_cluster)).to match_array(names)
      end
    end
  end

  describe 'flush' do
    it 'creates a MDM cluster' do
      provider.instance_variable_get(:@property_hash)[:mdm_names] = ['mdm-1']
      provider.instance_variable_get(:@property_hash)[:tb_names] = []

      provider.instance_variable_get(:@property_flush)[:mdm_names] = ['mdm-1', 'mdm-2']
      provider.instance_variable_get(:@property_flush)[:tb_names] = ['mdm-3']

      provider.expects(:scli).with('--switch_cluster_mode', '--cluster_mode', '3_node', '--add_slave_mdm_name', 'mdm-2', '--add_tb_name', 'mdm-3').returns([])
      provider.flush
    end
  end
end
