#require 'puppet/provider/blocker'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_sds).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO SDS's."

  mk_resource_methods

  def self.instances
    Puppet.debug("Getting SDS instances.")

    # get protection domains to lookup the name by the id
    pdos = scli_query_properties('--object_type', 'PROTECTION_DOMAIN', '--all_objects', '--properties', 'NAME')

    # get storage pools to lookup the name by the id
    pools = scli_query_properties('--object_type', 'STORAGE_POOL', '--all_objects', '--properties', 'NAME')

    # get devices to lookup the path by the id
    devices = scli_query_properties('--object_type', 'DEVICE', '--all_objects', '--properties', 'ORIGINAL_PATH,STORAGE_POOL_ID')

    # get rfcache devices to lookup the path by the id
    rfcache_devices = scli_query_properties('--object_type', 'RFCACHE_DEVICE', '--all_objects', '--properties', 'ORIGINAL_PATH,SDS_ID')

    # get fault sets to lookup the path by the id
    fault_sets = scli_query_properties('--object_type', 'FAULT_SET', '--all_objects', '--properties', 'NAME')

    sds_instances = []

    sdss = scli_query_properties('--object_type', 'SDS', '--all_objects', '--properties', 'NAME,IPS,DEVICE_ID_LIST,PORT,RMCACHE_ENABLED,RMCACHE_SIZE,PROTECTION_DOMAIN_ID,FAULT_SET_ID,RFCACHE_ENABLED')
    sdss.each do |sds_id, sds|

      # create a hash with all devices of the SDS grouped by the storage pool they are in
      pool_devices = Hash.new { |h, k| h[k] = [] }
      if sds['DEVICE_ID_LIST'] !~ /none/i
        sds['DEVICE_ID_LIST'].split(',').each do |device_id|
          device = devices[device_id]
          device_pool = pools[device['STORAGE_POOL_ID']]['NAME']
          pool_devices[device_pool] << device['ORIGINAL_PATH']
        end
      end

      rfcache_sds_devices = []
      rfcache_devices.each do | rf_id, rf_device |
        if sds_id == rf_device['SDS_ID']
          rfcache_sds_devices << rf_device['ORIGINAL_PATH']
        end
      end

      ramcache_size = -1
      if sds['RMCACHE_ENABLED'] =~ /Yes/i
        ramcache_size = convert_size_to_bytes(sds['RMCACHE_SIZE']) / 1024**2 # convert the size to MB
      end

      fault_set_name = nil
      if fault_sets.has_key?(sds['FAULT_SET_ID'])
        fault_set_name = fault_sets[sds['FAULT_SET_ID']]['NAME']
      end

      sds_instances << new({
                               :name => sds['NAME'],
                               :ensure => :present,
                               :protection_domain => pdos[sds['PROTECTION_DOMAIN_ID']]['NAME'],
                               :ips => sds['IPS'].split(','),
                               :port => sds['PORT'],
                               :pool_devices => pool_devices,
                               :ramcache_size => ramcache_size,
                               :fault_set => fault_set_name,
                               :rfcache_devices => rfcache_sds_devices,
                               :rfcache => sds['RFCACHE_ENABLED'] =~ /Yes/i ? 'enabled' : 'disabled',
                           })
    end

    Puppet.debug("Returning the SDS instances array: #{sds_instances}")
    sds_instances
  end

  def self.prefetch(resources)
    Puppet.debug("Prefetching SDS instances")
    sds = instances
    resources.keys.each do |name|
      if provider = sds.find { |sdsname| sdsname.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    Puppet.debug("Creating SDS #{@resource[:name]}")

    # Check if SDS is available/installed
    if @resource[:useconsul]
      first_ip = @resource[:ips][0]
      consul_key = "scaleio/cluster_setup/sds/#{first_ip}"
      if (!port_open?(first_ip, 7072))
        consul_max_tries(consul_key, 48)
        @property_hash[:ensure] = :absent
        return
      end
      consul_delete_key(consul_key)
    end

    first_add = true # act differently when adding the first devive of and sds

    # Go through each pool and add the devices
    @resource[:pool_devices].each do |storage_pool, devices|
      Puppet.debug("Adding devices #{devices} to pool #{storage_pool}")
      devices.each do |device|
        # act differently when adding the first devive of an sds
        if first_add
          create_sds = ["--add_sds", "--sds_name", @resource[:name], "--protection_domain_name", @resource[:protection_domain]]
          create_sds << "--device_path" << device
          create_sds << "--sds_ip" << @resource[:ips].join(",")
          create_sds << "--storage_pool_name" << "#{storage_pool}"
          create_sds << "--sds_port" << "#{@resource[:port]}" if @resource[:port]
          create_sds << "--fault_set_name" << "#{@resource[:fault_set]}" if @resource[:fault_set]
          scli(*create_sds)
          self.ramcache_size = @resource[:ramcache_size]
          first_add = false
        else
          scli("--add_sds_device", "--sds_name", @resource[:name], "--device_path", device, "--storage_pool_name", storage_pool)
        end
      end
    end
    @resource[:rfcache_devices].each do |rfcache_device|
      scli("--add_sds_rfcache_device", "--sds_name", @resource[:name], "--rfcache_device_path", rfcache_device)
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.debug("Destroying SDS #{@resource[:name]}")
    scli("--remove_sds", "--sds_name", resource[:name])
    @property_hash[:ensure] = :absent
  end

  def protection_domain=(value)
    fail("Changing the protection domain of a ScaleIO SDS is not supported")
  end

  def fault_set=(value)
    fail("Changing the fault set of a ScaleIO SDS is not supported")
  end

  def ramcache_size=(value)
    if (value >= 0)
      Puppet.debug("Setting SDS RAM cache size to #{value} MB")
      scli("--enable_sds_rmcache", "--sds_name", @resource[:name], "--i_am_sure")
      scli("--set_sds_rmcache_size", "--sds_name", @resource[:name], "--rmcache_size_mb", value, "--i_am_sure")
    else
      Puppet.debug("Disabling SDS RAM")
      scli("--disable_sds_rmcache", "--sds_name", @resource[:name], "--i_am_sure")
    end
  end

  def ips=(value)
    fail("SDS must have at least one IP address") if value.empty?

    # Add new IPs
    add_ips = value - @property_hash[:ips]
    add_ips.each do |ip|
      Puppet.debug("Adding SDS IP address #{ip} to SDS #{@resource[:name]}")
      scli("--add_sds_ip", "--sds_name", @resource[:name], "--new_sds_ip", ip)
    end

    # Remove obsolete IPs
    remove_ips = @property_hash[:ips] - value
    remove_ips.each do |ip|
      Puppet.debug("Removing SDS IP address #{ip} from SDS #{@resource[:name]}")
      scli("--remove_sds_ip", "--sds_name", @resource[:name], "--sds_ip_to_remove", ip)
    end
    @property_hash[:ensure] = :present
  end

  def pool_devices=(value)
    numDevices = 0
    value.each { |k, v| numDevices += v.length }
    fail("Cannot remove all SDS devices from SDS") if numDevices == 0

    # Loop over each defined pool and check for new devices
    value.each do |storage_pool, devices|
      existing_devices = @property_hash[:pool_devices][storage_pool]
      add_devices = devices - (existing_devices.kind_of?(Array) ? existing_devices : [])
      add_devices.each do |device|
        Puppet.debug("Adding SDS device #{device} to SDS #{@resource[:name]}")
        scli("--add_sds_device", "--sds_name", @resource[:name], "--storage_pool_name", storage_pool, "--device_path", device)
      end
    end

    # Loop over each existing pool and check for devices to be removed
    @property_hash[:pool_devices].each do |storage_pool, devices|
      defined_devices = value[storage_pool]
      remove_devices = devices - (defined_devices.kind_of?(Array) ? defined_devices : [])
      remove_devices.each do |device|
        Puppet.debug("Removing SDS device #{device} from SDS #{@resource[:name]}")
        scli("--remove_sds_device", "--sds_name", @resource[:name], "--device_path", device)
      end
    end
    @property_hash[:ensure] = :present
  end

  def port=(value)
    Puppet.debug("Modifying SDS Port to #{value}")
    scli("--modify_sds_port", "--sds_name", @resource[:name], "--new_sds_port", value)
    @property_hash[:ensure] = :present
  end

  def addSDSDevices(storage_pool, devices)
    devices.each do |device|
      scli("--add_sds_device", "--sds_name", @resource[:name], "--storage_pool_name", storage_pool, "--device_path", device)
    end
  end

  def rfcache_devices=(value)
    # Add new rfcache devices
    add_devices = value - @property_hash[:rfcache_devices]
    add_devices.each do |device|
      Puppet.debug("Adding SDS rfcache device #{device} to SDS #{@resource[:name]}")
      scli("--add_sds_rfcache_device", "--sds_name", @resource[:name], "--rfcache_device_path", device)
    end

    # Remove obsolete rfcache devices
    remove_devices = @property_hash[:rfcache_devices] - value
    remove_devices.each do |device|
      Puppet.debug("Removing SDS rfcache device #{device} from SDS #{@resource[:name]}")
      scli("--remove_sds_rfcache_device", "--sds_name", @resource[:name], "--rfcache_device_path", device)
    end
    @property_hash[:ensure] = :present
  end

  def rfcache=(value)
    if value == 'enabled'
      Puppet.debug("Enabling SDS rfcache")
      scli("--enable_sds_rfcache", "--sds_name", @resource[:name])
    else
      Puppet.debug("Disabling SDS rfcache")
      scli("--disable_sds_rfcache", "--sds_name", @resource[:name])
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_SDS: checking existence of ScaleIO SDS #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
