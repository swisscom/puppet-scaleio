require 'spec_helper'

describe Puppet::Type.type(:scaleio_fault_set).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_fault_set).new(
      {
          :ensure => :present,
          :name => 'myPDomain:myNewFaultSet',
      }
  ) }

  let(:no_fault_set) { my_fixture_read('prop_empty.cli') }
  let(:multiple_fault_sets) { my_fixture_read('prop_fault_set_multiple.cli') }
  let(:pdos) { my_fixture_read('prop_pdo_multiple.cli') }


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
    before :each do
      provider.class.stubs(:scli).with('--query_properties', '--object_type', 'PROTECTION_DOMAIN', any_parameters()).returns(pdos)
    end
    context 'with multiple fault sets' do
      before :each do
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'FAULT_SET', any_parameters()).returns(multiple_fault_sets)
        @instances = provider.class.instances

      end
      it 'detects all fault sets' do
        names = @instances.collect { |x| x.name }
        expect(['pdo:faultset1', 'pdo:faultset2']).to match_array(names)
      end
    end
    context 'with no fault set' do
      before :each do
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'FAULT_SET', any_parameters()).returns(no_fault_set)
        @instances = provider.class.instances
      end
      it 'detects no fault set' do
        names = @instances.collect { |x| x.name }
        expect([]).to match_array(names)
      end
    end
  end

  describe 'create' do
    it 'creates a fault set' do
      provider.expects(:scli).with('--add_fault_set', '--protection_domain_name', 'myPDomain', '--fault_set_name', 'myNewFaultSet').returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a fault set' do
      provider.expects(:scli).with('--remove_fault_set', '--protection_domain_name', 'myPDomain', '--fault_set_name', 'myNewFaultSet').returns([])
      provider.destroy
    end
  end
end
