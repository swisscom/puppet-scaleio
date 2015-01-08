require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_volume).provide(:scaleio_volume) do 
  include Puppet::Provider::Scli

  desc "Manages ScaleIO volume's."

  confine :osfamily => :redhat

  commands :sleep => 'sleep'

  mk_resource_methods
  
  def self.instances
    Puppet.debug("Getting volume instances.")
    volume_instances=[]
    query_all_volumes_lines = scli('--query_all_volumes').split("\n")
    
    # Iterate over all configured volumes
    query_all_volumes_lines.each do |line|
      next if line !~/Volume ID/

      # Get information about the volume
      name = line.match(/Name:(.*)Size/m)[1].strip
      size = line.match(/Size:\s*([\d\.]+)\s*GB/m)[1].strip.to_i
      type = line.match(/([\w]+)-provisioned/m)[1].strip.downcase
      pool=nil
      pdomain=nil
      sdc_nodes = []

      # Get more information about the volume
      query_volume_lines = scli("--query_volume", "--volume_name", name).split("\n")
      query_volume_lines.each do |line|
        # extract pool and protection domain name
        if line =~ /Protection Domain/
          pdomain = line.match(/Name:(.*)/)[1].strip
        elsif line =~ /Storage Pool/
          pool = line.match(/Name:(.*)/)[1].strip
        elsif line =~ /SDC ID/
          sdc_ip = line.match(/IP:\s*([\d\.]+)/)[1].strip

          # resolved sdc ip to sdc name
          sdc_name = scli("--query_all_sdc").match(/Name:\s*([\w\-]+)\s*IP:\s*#{sdc_ip}/)[1].strip
          sdc_nodes << sdc_name
        end
      end

      # Create volume instances hash
      new volume_instance = { 
        :name => name,
        :ensure => :present,
        :protection_domain => pdomain,
        :storage_pool => pool,
        :sdc_nodes => sdc_nodes,
        :size => size,
        :type => type,
      }
      volume_instances << new(volume_instance)
    end
    
    # Return the volume array
    Puppet.debug("Returning the volume instances array.")
    volume_instances
  end
  
  def self.prefetch(resources)
    Puppet.debug("Prefetching volume instances")
    volume = instances
    resources.keys.each do |name|
      if provider = volume.find{ |volumename| volumename.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create 
    Puppet.debug("Creating volume #{@resource[:name]}")
    sleep(20)  # wait for rebalance in case the pool has just been created
    cmd = [] << '--add_volume' << '--protection_domain_name' << @resource[:protection_domain] << '--storage_pool_name' << @resource[:storage_pool] << '--volume_name' << @resource[:name] << '--size_gb' << @resource[:size]
    cmd << '--thin_provisioned' if @resource[:type] == 'thin'
    scli(*cmd)

    @resource[:sdc_nodes].each do |node|
      Puppet.debug("Mapping volume #{@resource[:name]} to SDC node #{node}")
      scli('--map_volume_to_sdc', '--volume_name', @resource[:name], '--sdc_name', node, '--allow_multi_map')
    end
    @property_hash[:ensure] = :present
  end

  def destroy
   Puppet.debug("Destroying volume #{@resource[:name]}")
   scli("--remove_volume", "--volume_name", resource[:name], '--i_am_sure')
   @property_hash[:ensure] = :absent
  end
  
  def protection_domain=(value)
    fail("Changing the protection domain of a ScaleIO volume is not supported")
  end
  
  def storage_pool=(value)
    fail("Changing the storage pool of a ScaleIO volume is not supported")
  end
  
  def type=(value)
    fail("Changing the type of a ScaleIO volume is not supported")
  end
  
  def size=(value)
    fail("Decreasing the size of a ScaleIO volume is not allowed through Puppet.") if value < @property_hash[:size]
     Puppet.debug("Resizing volume #{@resource[:name]} to #{value} GB")
    scli('--modify_volume_capacity', '--volume_name', @resource[:name], '--size_gb', value)
  end

  def sdc_nodes=(value)
    # Check for new SDC nodes
    new_nodes = value - @property_hash[:sdc_nodes]
    new_nodes.each do |new_node|
      Puppet.debug("Mapping volume #{@resource[:name]} to SDC node #{new_node}")
      scli('--map_volume_to_sdc', '--volume_name', @resource[:name], '--sdc_name', new_node, '--allow_multi_map')
    end

    # Check for nodes to be unmapped from this volume
    rem_nodes = @property_hash[:sdc_nodes] - value
    rem_nodes.each do |rem_node|
      Puppet.debug("Unmapping volume #{@resource[:name]} from SDC node #{rem_node}")
      scli('--unmap_volume_from_sdc', '--volume_name', @resource[:name], '--sdc_name', rem_node, '--i_am_sure')
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_volume: checking existence of ScaleIO volume #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
