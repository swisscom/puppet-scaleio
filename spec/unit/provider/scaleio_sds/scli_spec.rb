require 'spec_helper'

describe Puppet::Type.type(:scaleio_sds).provider(:scli) do

  let(:provider) { described_class.new(resource) }
  let(:resource) { Puppet::Type.type(:scaleio_sds).new(
      {
          :ensure => :present,
          :name => 'mySDS',
          :protection_domain => 'myPDomain',
          :ips => ['172.17.121.10'],
          :port => 3454,
          :useconsul => false,
          :ramcache_size => 1024,
          :pool_devices => {'myPool' => ['/dev/sda', '/dev/sdb']},
          :fault_set => 'myFaultSet',
      }
  ) }

  let(:consul_provider) { Puppet::Type.type(:consul_kv).new(
      {
          :name => "key",
          :value => '1'
      }).provider
  }

  let(:no_sds) { my_fixture_read('prop_empty.cli') }
  let(:multiple_sds) { my_fixture_read('prop_sds_multiple.cli') }
  let(:pdos) { my_fixture_read('prop_pdo_multiple.cli') }
  let(:pools) { my_fixture_read('prop_pool_multiple.cli') }
  let(:devices) { my_fixture_read('prop_device_multiple.cli') }
  let(:fault_sets) { my_fixture_read('prop_fault_set_multiple.cli') }


  describe 'basics' do
    properties = [:ips, :port, :pool_devices, :ramcache_size, :fault_set]

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
    context 'with multiple SDSs' do
      before :each do
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'PROTECTION_DOMAIN', any_parameters()).returns(pdos)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'STORAGE_POOL', any_parameters()).returns(pools)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'DEVICE', any_parameters()).returns(devices)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'FAULT_SET', any_parameters()).returns(fault_sets)
        provider.class.stubs(:scli).with('--query_properties', '--object_type', 'SDS', any_parameters()).returns(multiple_sds)
        @instances = provider.class.instances
      end
      it 'detects all SDSs' do
        names = @instances.collect { |x| x.name }
        expect(%w(sds-1 sds-2 sds-3)).to match_array(names)
      end
      it 'with correct ips' do
        expect(@instances[0].ips).to match_array(['192.168.56.123'])
        expect(@instances[2].ips).to match_array(['192.168.56.122', '192.168.56.128'])
      end
      it 'with correct ports' do
        expect(@instances[0].port).to match(/^7072$/)
        expect(@instances[2].port).to match(/^8000/)
      end
      it 'with correct pool devices' do
        expect(@instances[0].pool_devices).to eql({'pool1' => ['/dev/sdb']})
        expect(@instances[2].pool_devices).to eql({'pool1' => ['/dev/sdb', '/dev/sdc']})
      end
      it 'with correct ram cache' do
        expect(@instances[0].ramcache_size).to match(128)
        expect(@instances[1].ramcache_size).to match(-1)
        expect(@instances[2].ramcache_size).to match(98304)
      end
      it 'with correct fault set' do
        expect(@instances[0].fault_set).to eql('faultset2')
        expect(@instances[1].fault_set).to eql(:absent)
        expect(@instances[2].fault_set).to eql('faultset1')
      end
      it 'with correct protection domain' do
        expect(@instances[0].protection_domain).to match('pdo')
      end
    end
    context 'with no SDS' do
      before :each do
        provider.class.stubs(:scli).with(any_parameters()).returns(no_sds)
        @instances = provider.class.instances
      end
      it 'detects no SDS' do
        names = @instances.collect { |x| x.name }
        expect([]).to match_array(names)
      end
    end
  end

  describe 'create' do
    it 'creates a sds' do
      provider.expects(:scli).with('--add_sds', '--sds_name', 'mySDS', '--protection_domain_name', 'myPDomain', '--device_path', '/dev/sda', '--sds_ip', '172.17.121.10', '--storage_pool_name', 'myPool', '--sds_port', '3454', '--fault_set_name', 'myFaultSet').returns([])
      provider.expects(:scli).with('--add_sds_device', '--sds_name', 'mySDS', '--device_path', '/dev/sdb', '--storage_pool_name', 'myPool').returns([])
      provider.expects(:scli).with('--enable_sds_rmcache', '--sds_name', 'mySDS', '--i_am_sure').returns([])
      provider.expects(:scli).with('--set_sds_rmcache_size', '--sds_name', 'mySDS', '--rmcache_size_mb', 1024, '--i_am_sure').returns([])
      provider.create
    end
  end

  describe 'with consul' do
    it 'fails creating an sds, when sds port (7072) is not reachable for n times (using consul)' do
      expect {
        provider.class.stubs(:port_open?).with('172.17.121.10', 7072, 1).returns(false)
        provider.instance_variable_get(:@resource)[:useconsul] = true
        Puppet::Type.type(:consul_kv).provider(:default).any_instance.stubs(:send).with('value').returns('50')
        provider.create
      }.to raise_error Puppet::Error, /Reached max_tries/
    end

    it 'creates an sds, when sds port (7072) is reachable (using consul)' do
      provider.class.stubs(:port_open?).with('172.17.121.10', 7072, 1).returns(true)
      provider.instance_variable_get(:@resource)[:useconsul] = true
      provider.expects(:consul_delete_key).returns()
      provider.expects(:scli).with('--add_sds', '--sds_name', 'mySDS', '--protection_domain_name', 'myPDomain', '--device_path', '/dev/sda', '--sds_ip', '172.17.121.10', '--storage_pool_name', 'myPool', '--sds_port', '3454', '--fault_set_name', 'myFaultSet').returns([])
      provider.expects(:scli).with('--add_sds_device', '--sds_name', 'mySDS', '--device_path', '/dev/sdb', '--storage_pool_name', 'myPool').returns([])
      provider.expects(:scli).with('--enable_sds_rmcache', '--sds_name', 'mySDS', '--i_am_sure').returns([])
      provider.expects(:scli).with('--set_sds_rmcache_size', '--sds_name', 'mySDS', '--rmcache_size_mb', 1024, '--i_am_sure').returns([])
      provider.create
    end

    it 'wait for creating an sds, when sds port (7072) is not reachable (using consul)' do
      provider.class.stubs(:port_open?).with('172.17.121.10', 7072, 1).returns(false)
      provider.instance_variable_get(:@resource)[:useconsul] = true
      Puppet::Type.type(:consul_kv).provider(:default).any_instance.stubs(:send).with('value').returns('5')
      Puppet::Type.type(:consul_kv).provider(:default).any_instance.stubs(:send).with('create').returns()

      provider.create
    end
  end

  describe 'destroy' do
    it 'removes a sds' do
      provider.expects(:scli).with('--remove_sds', '--sds_name', 'mySDS').returns([])
      provider.destroy
    end
  end

  describe 'update port' do
    it 'updates the port' do
      provider.expects(:scli).with('--modify_sds_port', '--sds_name', 'mySDS', '--new_sds_port', 453).returns([])
      provider.port = 453
    end
  end

  describe 'managing RAM cache' do
    it 'enables the RAM cache and sets the correct size' do
      provider.expects(:scli).with('--enable_sds_rmcache', '--sds_name', 'mySDS', '--i_am_sure').returns([])
      provider.expects(:scli).with('--set_sds_rmcache_size', '--sds_name', 'mySDS', '--rmcache_size_mb', 453, '--i_am_sure').returns([])
      provider.ramcache_size = 453
    end
    it 'disabled the RAM cache' do
      provider.expects(:scli).with('--disable_sds_rmcache', '--sds_name', 'mySDS', '--i_am_sure').returns([])
      provider.ramcache_size = -1
    end
  end

  describe 'update pool_devices' do
    it 'removes obsolte pool devices' do
      provider.instance_variable_get(:@property_hash)[:pool_devices] = {'myPool' => ['/dev/sda', '/dev/sdb', '/dev/sdc']}
      provider.expects(:scli).with('--remove_sds_device', '--sds_name', 'mySDS', '--device_path', '/dev/sdc').returns([])
      provider.pool_devices = {'myPool' => ['/dev/sda', '/dev/sdb']}
    end

    it 'adds new pool devices' do
      provider.instance_variable_get(:@property_hash)[:pool_devices] = {'myPool' => ['/dev/sda', '/dev/sdb']}
      provider.expects(:scli).with('--add_sds_device', '--sds_name', 'mySDS', '--storage_pool_name', 'myPool', '--device_path', '/dev/sdd').returns([])
      provider.pool_devices = {'myPool' => ['/dev/sda', '/dev/sdb', '/dev/sdd']}
    end

    it 'does nothing' do
      provider.instance_variable_get(:@property_hash)[:pool_devices] = {'myPool' => ['/dev/sda', '/dev/sdb']}
      provider.pool_devices = {'myPool' => ['/dev/sda', '/dev/sdb']}
    end

    it 'requires at least one device' do
      expect {
        provider.pool_devices = {'myPool' => []}
      }.to raise_error Puppet::Error, /Cannot remove all SDS devices from SDS/
    end
  end

  describe 'update IPs' do
    it 'removes obsolte IPs' do
      provider.instance_variable_get(:@property_hash)[:ips] = ['172.17.121.10', '172.17.121.11']
      provider.expects(:scli).with('--remove_sds_ip', '--sds_name', 'mySDS', '--sds_ip_to_remove', '172.17.121.11').returns([])
      provider.ips = ['172.17.121.10']
    end

    it 'adds new IPs' do
      provider.instance_variable_get(:@property_hash)[:ips] = ['172.17.121.10']
      provider.expects(:scli).with('--add_sds_ip', '--sds_name', 'mySDS', '--new_sds_ip', '172.17.121.11').returns([])
      provider.ips = ['172.17.121.10', '172.17.121.11']
    end

    it 'does nothing' do
      provider.instance_variable_get(:@property_hash)[:ips] = ['172.17.121.10']
      provider.ips = ['172.17.121.10']
    end

    it 'requires at least one IP' do
      expect {
        provider.ips = []
      }.to raise_error Puppet::Error, /SDS must have at least one IP address/
    end
  end
end
