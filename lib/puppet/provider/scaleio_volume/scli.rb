require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_volume).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO volume's."

  confine :osfamily => :redhat

  commands :sleep => 'sleep'

  mk_resource_methods

  def self.instances
    Puppet.debug("Getting volume instances.")

    # get protection domains to lookup the name by the id
    pdos = scli_query_properties('--object_type', 'PROTECTION_DOMAIN', '--all_objects', '--properties', 'NAME')

    # get pools to lookup the name by the id
    pools = scli_query_properties('--object_type', 'STORAGE_POOL', '--all_objects', '--properties', 'NAME,PROTECTION_DOMAIN_ID')

    # get sdcs to lookup the name by the id
    sdcs = scli_query_properties('--object_type', 'SDC', '--all_objects', '--properties', 'NAME')

    volume_instances = []

    volumes = scli_query_properties('--object_type', 'VOLUME', '--all_objects', '--properties', 'NAME,SIZE,TYPE,STORAGE_POOL_ID,TYPE,MAPPED_SDC_ID_LIST')
    volumes.each do |volume_id, volume|
      next if volume['TYPE'] !~ /(THIN|THICK)_PROVISIONED/  # we do not manage snapshots

      pool = pools[volume['STORAGE_POOL_ID']]
      pool_name = pool['NAME']
      pdomain = pdos[pool['PROTECTION_DOMAIN_ID']]['NAME']

      sdc_nodes = []
      volume['MAPPED_SDC_ID_LIST'].split(',').each do |sdc_id|
        sdc_nodes << sdcs[sdc_id]['NAME']
      end

      volume_instances << new({
                                :name => volume['NAME'],
                                :ensure => :present,
                                :protection_domain => pdomain,
                                :storage_pool => pool_name,
                                :sdc_nodes => sdc_nodes,
                                :size => convert_size_to_bytes(volume['SIZE']) / 1024 ** 3,
                                :type => volume['TYPE'] =~ /THICK_PROVISIONED/ ? 'thick' : 'thin',
                            })
    end

    Puppet.debug("Returning the SDS instances array: #{volume_instances}")
    volume_instances
  end

  def self.prefetch(resources)
    Puppet.debug("Prefetching volume instances")
    volume = instances
    resources.keys.each do |name|
      if provider = volume.find { |volumename| volumename.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    Puppet.debug("Creating volume #{@resource[:name]}")
    sleep(5) # wait for rebalance
    cmd = [] << '--add_volume' << '--protection_domain_name' << @resource[:protection_domain] << '--storage_pool_name' << @resource[:storage_pool] << '--volume_name' << @resource[:name] << '--size_gb' << @resource[:size]
    cmd << '--thin_provisioned' if @resource[:type] == 'thin'
    scli(*cmd)

    sdc_names = get_all_sdc_names()
    @resource[:sdc_nodes].each do |node|
      if (sdc_names.include?(node))
        Puppet.debug("Mapping volume #{@resource[:name]} to SDC node #{node}")
        scli('--map_volume_to_sdc', '--volume_name', @resource[:name], '--sdc_name', node, '--allow_multi_map')
      end
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
    sdc_names = get_all_sdc_names()

    # Check for new SDC nodes
    new_nodes = value - @property_hash[:sdc_nodes]
    new_nodes.each do |new_node|
      if (sdc_names.include?(new_node))
        Puppet.debug("Mapping volume #{@resource[:name]} to SDC node #{new_node}")
        scli('--map_volume_to_sdc', '--volume_name', @resource[:name], '--sdc_name', new_node, '--allow_multi_map')
      end
    end

    # Check for nodes to be unmapped from this volume
    rem_nodes = @property_hash[:sdc_nodes] - value
    rem_nodes.each do |rem_node|
      Puppet.debug("Unmapping volume #{@resource[:name]} from SDC node #{rem_node}")
      scli('--unmap_volume_from_sdc', '--volume_name', @resource[:name], '--sdc_name', rem_node, '--i_am_sure')
    end
  end

  def get_all_sdc_names()
    sdc_names=[]
    query_all_sdc_lines = scli('--query_all_sdc').split("\n")

    # Iterate through each SDS block
    query_all_sdc_lines.each do |line|
      next if line !~/SDC ID/

      # Get information about the SDC
      name = line.match(/Name:(.*)IP/m)[1].strip

      next if name =~ /^N\/A$/

      sdc_names << name
    end
    sdc_names
  end

  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_volume: checking existence of ScaleIO volume #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
