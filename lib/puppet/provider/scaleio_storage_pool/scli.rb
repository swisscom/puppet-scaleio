Puppet::Type.type(:scaleio_storage_pool).provide(:scaleio_storagepool) do

  desc "Manages ScaleIO Storage Pool."

  confine :osfamily => :redhat

  commands :scli => "/var/lib/puppet/module_data/scaleio/scli_wrap"
  
  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::scaleio_storage_pool: got to self.instances.")
    
    # First have to get a list of pdomains
    pdomain_names = []
    begin
      query_all = scli("--query_all")
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error Querying Cluster -> #{e.inspect}"
    end
    lines = query_all.split("\n")
    pdomain = ''    
    # Iterate through the Protection Domain block
    lines.each do |line|
      
      # Pull out protection domain name
      if line =~/^Protection Domain/
        pdomain = line.split(' ')[2]
        pdomain_names << pdomain
      end
    end
    
    
    pdomain_pools = Hash.new {|h,k| h[k] = [] }
 
    # Get a list of storage pools in each pdomain
    pdomain_names.each do |pdomain|
      poolNames = []
      begin
        lines = scli("--query_protection_domain", "--protection_domain_name", pdomain).split("\n")
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error, "Error querying Protection Domain #{pdomain} -> #{e.inspect}"
      end
    
      lines.each do |line|
				if line =~/^Storage Pool/
					poolName = line.split(' ')[2]
					poolNames << poolName
				end
      end
      # Build up hash of protection domains and their storage pools
      pdomain_pools[pdomain] << poolNames
    end
    
    storage_pool_instances = [] 
		storage_pool_info = {}
    # Get detailed info for each storage pool
    pdomain_pools.each do |pdomain, pools|
      pools.flatten.each do |pool| 
        begin
          pool_query_lines = scli("--query_storage_pool", "--storage_pool_name", pool, "--protection_domain_name", pdomain).split("\n")
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "Error querying Storagepool #{pool} -> #{e.inspect}"
        end
        pool_query_lines.each do |line|
          if line =~/Spare policy/
						spare_pct = line.match /([0-9\.]+%)/
            @spare_policy = spare_pct[1];
          end  
        end
        # Create storage pools hash
        new storage_pool_info = { :name => pool,
                 :ensure => :present,
                 :protection_domain => pdomain,
                 :spare_policy => @spare_policy  }
        storage_pool_instances << new(storage_pool_info)
      end
    end
    Puppet.debug("Puppet::Provider::ScaleIO_Storagepool: Returning Storage Pool array")
    storage_pool_instances
  end

  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::ScaleIO_Storagepool: Got to self.prefetch")
    pool = instances
    resources.keys.each do |name|
      if provider = pool.find{ |poolname| poolname.name == name }
        resources[name].provider = provider
      end
    end
  end
  
  def create 
    Puppet.debug("Puppet::Provider::ScaleIO_Storagepool: Creating Storage Pool #{resource[:name]}")
    begin
      result = scli("--add_storage_pool", "--protection_domain_name", resource[:protection_domain], "--storage_pool_name", resource[:name])
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error creating Storage Pool #{@resource[:name]} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    begin
			result = scli("--remove_storage_pool", "--protection_domain_name", @property_hash[:protection_domain], "--storage_pool_name", resource[:name])	# TODO: ask if using property hash for removing is correct (resource not working when using purge)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error Removing Storage Pool #{@resource[:name]} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :absent
  end
  
  def new_name=(value)
    Puppet.debug("Puppet::Provider::ScaleIO_Storagepool: Changing Storage Pool name name to #{value}")
    begin
      result = scli("--rename_storage_pool", "--protection_domain_name", resource[:protection_domain], "--storage_pool_name", resource[:name], "--new_name", value)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error Renaming Storage Pool #{@resource[:name]} to #{value}} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :present
  end
 
  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_Storagepool: checking existence of ScaleIO Storage Pool #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end


end

