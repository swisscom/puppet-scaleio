require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_sds).provide(:scaleio_sds) do 
  include Puppet::Provider::Scli

  desc "Manages ScaleIO SDS's."

  confine :osfamily => :redhat

  mk_resource_methods
  
  def self.instances
    Puppet.debug("Getting SDS instances.")
    sds_instances=[]
    query_all_sds_lines = scli('--query_all_sds').split("\n")
    
    # Iterate through each SDS block
    query_all_sds_lines.each do |line|
      next if line !~/SDS ID/

      # Get information about the SDS
      name = line.match(/Name:(.*)State/m)[1].strip
      ip = line.match(/IP:(.*)Port/m)[1].strip
      ips = ip.split(",").sort!
      port = line.split(' ')[-1]

      # Get devices and pool info for each SDS
      query_sds_lines = scli("--query_sds", "--sds_name", name).split("\n")
      protection_domain = ''
      current_path = ''
      pool_devices = Hash.new {|h,k| h[k] = [] }

      # First pull out the device path, then the pool it is assigned to
      query_sds_lines.each do |line|
        if line =~/Protection Domain/
          protection_domain = line.match(/Name: (.*)/)[1].strip
        elsif line =~/Path/
          current_path = line.match(/Path: (.*)  Original/m)[1].strip
        elsif line =~/Storage Pool/
          pool = line.match(/Storage Pool: (.*),/m)[1].strip 
          pool_devices[pool].push current_path
        end
      end

      # Create sds instances hash
      new sds_instance = { 
        :name => name,
        :ensure => :present,
        :protection_domain => protection_domain,
        :ips => ips,
        :port => port,
        :pool_devices => pool_devices,
      }
      sds_instances << new(sds_instance)
    end
    
    # Return the SDS array
    Puppet.debug("Returning the SDS instances array.")
    sds_instances
  end
  
  def self.prefetch(resources)
    Puppet.debug("Prefetching SDS instances")
    sds = instances
    resources.keys.each do |name|
      if provider = sds.find{ |sdsname| sdsname.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create 
    Puppet.debug("Creating SDS #{@resource[:name]}")

    first_add = true  # act differently when adding the first devive of and sds

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
          scli(*create_sds)
          first_add = false
        else
          scli("--add_sds_device", "--sds_name", @resource[:name], "--device_path", device, "--storage_pool_name", storage_pool)
        end
      end
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    Puppet.debug("Destroying SDS #{@resource[:name]}")
    scli("--remove_sds", "--sds_name", resource[:name])
    @property_hash[:ensure] = :absent
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
    value.each { |k,v| numDevices += v.length }
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

  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_SDS: checking existence of ScaleIO SDS #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
