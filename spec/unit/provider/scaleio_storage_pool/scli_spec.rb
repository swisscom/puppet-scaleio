require 'spec_helper'

describe Puppet::Type.type(:scaleio_storage_pool).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_storage_pool).new(
      {
          :ensure => :present,
          :name => 'myPDomain:myNewPool',
          :spare_policy => '34%',
      }
  ) }

  let(:no_pool) { my_fixture_read('prop_empty.cli') }
  let(:multiple_pools) { my_fixture_read('prop_pool_details_multiple.cli') }
  let(:pdos) { my_fixture_read('prop_pdo_multiple.cli') }


  describe 'basics' do
    properties = [:spare_policy, :ramcache]

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
    context 'with multiple pools' do
      before :each do
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'STORAGE_POOL', any_parameters()).returns(multiple_pools)
        @instances = provider.class.instances

      end
      it 'detects all pools' do
        names = @instances.collect { |x| x.name }
        expect(['pdo:pool1', 'pdo:pool2']).to match_array(names)
      end

      it 'with the correct spare policy' do
        expect(@instances[0].spare_policy).to match('34%')
        expect(@instances[1].spare_policy).to match('8%')
      end

      it 'with ram cache enabled' do
        expect(@instances[0].ramcache).to match('enabled')
      end

      it 'with ram cache disabled ' do
        expect(@instances[1].ramcache).to match('disabled')
      end
    end
    context 'with no pool' do
      before :each do
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'STORAGE_POOL', any_parameters()).returns(no_pool)
        @instances = provider.class.instances
      end
      it 'detects no pool' do
        names = @instances.collect { |x| x.name }
        expect([]).to match_array(names)
      end
    end
  end

  describe 'create' do
    it 'creates a storage pool' do
      provider.expects(:scli).with('--add_storage_pool', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool').returns([])
      provider.expects(:scli).with('--modify_spare_policy', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--spare_percentage', '34%', '--i_am_sure').returns([])
      provider.expects(:scli).with('--modify_zero_padding_policy', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--enable_zero_padding').returns([])
      provider.expects(:scli).with('--set_rmcache_usage', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--i_am_sure', '--use_rmcache').returns([])
      provider.expects(:sleep).with(5).returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a storage pool' do
      provider.expects(:scli).with('--remove_storage_pool', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool').returns([])
      provider.destroy
    end
  end

  describe 'update' do
    it 'updates the spare policy' do
      provider.expects(:scli).with('--modify_spare_policy', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--spare_percentage', '34%', '--i_am_sure').returns([])
      provider.updateSparePolicy('34%')
    end
    it 'updates the ramcache' do
      provider.expects(:scli).with('--set_rmcache_usage', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myNewPool', '--i_am_sure', '--dont_use_rmcache').returns([])
      provider.update_ramcache('disabled')
    end
  end
end
