require 'spec_helper'

provider_class = Puppet::Type.type(:scaleio_volume).provider(:scaleio_volume)
all_properties = [
  :protection_domain,
  :storage_pool,
  :size,
  :type,
  :sdc_nodes,
]

describe provider_class do

  # load sample cli outputs
  let(:fixtures_cli)    { File.expand_path(File.join(File.dirname(__FILE__),"../../../../fixtures/cli"))}
  let(:all_sdc)         { File.read(File.join(fixtures_cli,"vol_query_all_sdc.cli")) }
  let(:all_vol_none)    { File.read(File.join(fixtures_cli,"vol_query_all_volumes_none.cli")) }
  let(:all_vol_three)   { File.read(File.join(fixtures_cli,"vol_query_all_volumes_three.cli")) }
  let(:vol_myVol)       { File.read(File.join(fixtures_cli,"vol_query_vol_myVol.cli")) }
  let(:vol_myVol2)      { File.read(File.join(fixtures_cli,"vol_query_vol_myVol2.cli")) }
  let(:vol_myVol3)      { File.read(File.join(fixtures_cli,"vol_query_vol_myVol3.cli")) }


  let(:resource) {
    Puppet::Type.type(:scaleio_volume).new({
      :ensure            => :present,
      :name              => 'myVol',
      :protection_domain => 'myPDomain',
      :storage_pool      => 'myPool',
      :size              => 504,
      :type              => 'thin',
      :sdc_nodes         => ['sdc1', 'sdc2'],
      :provider          => described_class.name,
    })
  }

  let(:provider) { resource.provider }

  describe 'basics' do
    before :each do
      # Create a mock resource
      @resource          = stub 'resource'
      @name              = 'myNewVolume'
      @protection_domain = 'myPDomain'
      @storage_pool      = 'myPool'
      @size              = 504,
      @type              = 'thin',
      @sdc_nodes         = ['sdc1', 'sdc2'],
      # A catch all; no parameters set
      @resource.stubs(:[]).returns(nil)
      # But set name, ensure
      @resource.stubs(:[]).with(:name).returns @name
      @resource.stubs(:[]).with(:protection_domain).returns @protection_domain
      @resource.stubs(:[]).with(:storage_pool).returns @storage_pool
      @resource.stubs(:[]).with(:size).returns @size
      @resource.stubs(:[]).with(:type).returns @type
      @resource.stubs(:[]).with(:sdc_nodes).returns @sdc_nodes
      @resource.stubs(:[]).with(:ensure).returns :present
      @resource.stubs(:ref).returns "Scaleio_volume[#{@name}]"
      @provider = provider_class.new(@resource)
    end
    it("should have a create method")   { @provider.should respond_to(:create)  }
    it("should have a destroy method")  { @provider.should respond_to(:destroy) }
    it("should have an exists? method") { @provider.should respond_to(:exists?) }
    all_properties.each do |prop|
      it "should have a #{prop.to_s} method" do
        @provider.should respond_to(prop.to_s)
      end
      it "should have a #{prop.to_s}= method" do
        @provider.should respond_to(prop.to_s + "=")
      end
    end
  end

  describe 'self.instances' do
    it 'returns an array w/ no volumes' do
      provider.class.stubs(:scli).with('--query_all_volumes').returns(all_vol_none)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect([]).to match_array(names)
    end
    it 'returns an array w/ three volumes' do
      provider.class.stubs(:scli).with('--query_all_volumes').returns(all_vol_three)
      provider.class.stubs(:scli).with('--query_all_sdc').returns(all_sdc)
      provider.class.stubs(:scli).with('--query_volume', '--volume_name', 'myVol').returns(vol_myVol)
      provider.class.stubs(:scli).with('--query_volume', '--volume_name', 'myVol2').returns(vol_myVol2)
      provider.class.stubs(:scli).with('--query_volume', '--volume_name', 'myVol3').returns(vol_myVol3)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect(['myVol', 'myVol2', 'myVol3']).to match_array(names)
    end
    it 'has discoverd the correct property values' do
      provider.class.stubs(:scli).with('--query_all_volumes').returns(all_vol_three)
      provider.class.stubs(:scli).with('--query_all_sdc').returns(all_sdc)
      provider.class.stubs(:scli).with('--query_volume', '--volume_name', 'myVol').returns(vol_myVol)
      provider.class.stubs(:scli).with('--query_volume', '--volume_name', 'myVol2').returns(vol_myVol2)
      provider.class.stubs(:scli).with('--query_volume', '--volume_name', 'myVol3').returns(vol_myVol3)
      instances = provider.class.instances
      names     = instances.collect {|x| x.name }
      expect(instances[0].protection_domain).to match('myPDomain')
      expect(instances[0].storage_pool).to match('myPool')
      expect(instances[0].type).to match('thin')
      expect(instances[0].size).to eq(24)
      expect(instances[0].sdc_nodes).to match_array(['sdc2', 'sdc1'])
      expect(instances[2].type).to match('thick')
      expect(instances[2].storage_pool).to match('myPool2')
    end
  end

  describe 'create' do
    it 'creates a volume' do
      provider.expects(:get_all_sdc_names).returns(['sdc1', 'sdc2'])
      provider.expects(:scli).with('--add_volume', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myPool', '--volume_name', 'myVol', '--size_gb', 504, '--thin_provisioned').returns([])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc1', '--allow_multi_map').returns([])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc2', '--allow_multi_map').returns([])
      provider.create
    end
    it 'creates a volume only on connected sdc node' do
      provider.expects(:get_all_sdc_names).returns(['sdc2'])
      provider.expects(:scli).with('--add_volume', '--protection_domain_name', 'myPDomain', '--storage_pool_name', 'myPool', '--volume_name', 'myVol', '--size_gb', 504, '--thin_provisioned').returns([])
      provider.expects(:scli).with('--map_volume_to_sdc', '--volume_name', 'myVol', '--sdc_name', 'sdc2', '--allow_multi_map').returns([])
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
