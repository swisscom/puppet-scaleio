require 'spec_helper'

describe Puppet::Type.type(:scaleio_protection_domain).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_protection_domain).new(
      {
          :ensure => :present,
          :name => 'test-PDO',
      }
  ) }

  let(:no_pdo) { my_fixture_read('prop_empty.cli') }
  let(:multiple_pdo) { my_fixture_read('prop_pdo_multiple.cli') }

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
    it 'returns an array with no protection domains' do
      provider.class.stubs(:scli).with(any_parameters()).returns(no_pdo)
      pdo_instances = provider.class.instances
      pdo_names = pdo_instances.collect { |x| x.name }
      expect([]).to match_array(pdo_names)
    end

    it 'returns an array with multiple protection domains' do
      provider.class.stubs(:scli).with(any_parameters()).returns(multiple_pdo)
      pdo_instances = provider.class.instances
      pdo_names = pdo_instances.collect { |x| x.name }
      expect(['pdo', 'pdo2']).to match_array(pdo_names)
    end
  end

  describe 'create' do
    it 'creates a protection domain' do
      provider.expects(:scli).with('--add_protection_domain', '--protection_domain_name', 'test-PDO').returns([])
      provider.create
    end
  end
end
