require 'spec_helper'

describe Puppet::Type.type(:scaleio_volume).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_volume).new(
      {
          :ensure            => :present,
          :name              => 'myVol',
          :protection_domain => 'myPDomain',
          :storage_pool      => 'myPool',
          :size              => 504,
          :type              => 'thin',
          :sdc_nodes         => ['sdc1', 'sdc2'],
      }
  ) }


  let(:no_volume) { my_fixture_read('prop_empty.cli') }
  let(:multiple_volumes) { my_fixture_read('prop_volume_multiple.cli') }
  let(:pdos) { my_fixture_read('prop_pdo_multiple.cli') }
  let(:pools) { my_fixture_read('prop_pool_pdo_multiple.cli') }
  let(:sdcs) { my_fixture_read('prop_sdc_multiple.cli') }

  describe 'basics' do
    properties = [  :protection_domain,:storage_pool,:size,:type,:sdc_nodes]

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
    context 'with multiple volumes' do
      before :each do
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'PROTECTION_DOMAIN', any_parameters()).returns(pdos)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'STORAGE_POOL', any_parameters()).returns(pools)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'SDC', any_parameters()).returns(sdcs)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'VOLUME', any_parameters()).returns(multiple_volumes)
        @instances = provider.class.instances
      end
      it 'detects all volumes' do
        names = @instances.collect { |x| x.name }
        expect(%w(volume-1 volume-2)).to match_array(names)
      end
      it 'with correct nodes' do
        expect(@instances[0].sdc_nodes).to match_array(['sdc-1'])
        expect(@instances[1].sdc_nodes).to match_array(['sdc-1','sdc-2','sdc-3'])
      end
      it 'with correct size' do
        expect(@instances[0].size).to eq(8)
        expect(@instances[1].size).to eq(32)
      end
      it 'with correct type' do
        expect(@instances[0].type).to match('thick')
        expect(@instances[1].type).to match('thin')
      end
      it 'with correct pool' do
        expect(@instances[0].storage_pool).to match('pool1')
      end
      it 'with correct protection domain' do
        expect(@instances[0].protection_domain).to match('pdo')
      end
    end
    context 'with no volume' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(no_volume)
        @instances = provider.class.instances
      end
      it 'detects no volume' do
        names = @instances.collect { |x| x.name }
        expect([]).to match_array(names)
      end
    end
  end


  describe 'create' do
    it 'creates a volume' do
      provider.expects(:get_all_sdc_names).returns(['sdc1', 'sdc2'])
      provider.expects(:scli).with('--add_volume', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myPool', '--volume_name', 'myVol', '--size_gb', 504, '--thin_provisioned').returns([])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc1', '--allow_multi_map').returns([])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc2', '--allow_multi_map').returns([])
      provider.expects(:sleep).with(5).returns([])
      provider.create
    end
    it 'creates a volume only on connected sdc node' do
      provider.expects(:get_all_sdc_names).returns(['sdc2'])
      provider.expects(:scli).with('--add_volume', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myPool', '--volume_name', 'myVol', '--size_gb', 504, '--thin_provisioned').returns([])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc2', '--allow_multi_map').returns([])
      provider.expects(:sleep).with(5).returns([])
      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a volume' do
      provider.expects(:scli).with('--remove_volume', '--volume_name', 'myVol', '--i_am_sure').returns([])
      provider.destroy
    end
  end

  describe 'update protection_domain' do
    it 'denies updating the vol protection_domain' do
      expect{
        provider.instance_variable_get(:@property_hash)[:protection_domain] = 'pd1'
        provider.protection_domain = 'pd2'
      }.to raise_error Puppet::Error, /Changing the protection domain of a ScaleIO volume is not supported/
    end
  end

  describe 'update storage_pool' do
    it 'denies updating the vol storage_pool' do
      expect{
        provider.instance_variable_get(:@property_hash)[:storage_pool] = 'pool1'
        provider.storage_pool = 'pool2'
      }.to raise_error Puppet::Error, /Changing the storage pool of a ScaleIO volume is not supported/
    end
  end

  describe 'update type' do
    it 'denies updating the vol type' do
      expect{
        provider.instance_variable_get(:@property_hash)[:type] = 'thick'
        provider.type = 'thin'
      }.to raise_error Puppet::Error, /Changing the type of a ScaleIO volume is not supported/
    end
  end

  describe 'update size' do
    it 'increases the vol size' do
      provider.instance_variable_get(:@property_hash)[:size] = 504
      provider.expects(:scli).with('--modify_volume_capacity', '--volume_name', 'myVol', '--size_gb', 1024).returns([])
      provider.size = 1024
    end
    it 'denies decreasing the vol size' do
      expect{
        provider.instance_variable_get(:@property_hash)[:size] = 504
        provider.size = 8
      }.to raise_error Puppet::Error, /Decreasing the size of a ScaleIO volume is not allowed through Puppet/
    end
  end

  describe 'update sdc_nodes' do
    it 'removes obsolte sdc node' do
      provider.instance_variable_get(:@property_hash)[:sdc_nodes] = ['sdc1', 'sdc2']
      provider.expects(:get_all_sdc_names).returns(['sdc1', 'sdc2'])
      provider.expects(:scli).with('--unmap_volume_from_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc2', '--i_am_sure').returns([])
      provider.sdc_nodes = ['sdc1']
    end

    it 'adds new sdc nodes' do
      provider.instance_variable_get(:@property_hash)[:sdc_nodes] = ['sdc1', 'sdc2']
      provider.expects(:get_all_sdc_names).returns(['sdc1', 'sdc2', 'sdc3'])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc3', '--allow_multi_map').returns([])
      provider.sdc_nodes = ['sdc1', 'sdc3', 'sdc2']
    end

    it 'does nothing' do
      provider.instance_variable_get(:@property_hash)[:sdc_nodes] = ['sdc1', 'sdc2']
      provider.expects(:get_all_sdc_names).returns(['sdc1', 'sdc2'])
      provider.sdc_nodes = ['sdc2', 'sdc1']
    end
  end
end
