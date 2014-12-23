require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_storage_pool).provide(:scaleio_storage_pool) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO Storage Pool."

  confine :osfamily => :redhat

	commands :sleep => 'sleep'

  mk_resource_methods

  def self.instances
    Puppet.debug('getting instances of storage pools')

    # First have to get a list of pdomains
    pdomains = getProtectionDomains

    pdomain_pools = Hash.new {|h,k| h[k] = [] }

    # Get a list of storage pools in each pdomain
    pdomains.each do |pdomain|
      poolNames = []

      lines = scli("--query_protection_domain", "--protection_domain_name", pdomain).split("\n")
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
        spare_policy = ""

        pool_query_lines = scli("--query_storage_pool", "--storage_pool_name", pool, "--protection_domain_name", pdomain).split("\n")
        pool_query_lines.each do |line|
          if line =~/Spare policy/
            spare_pct = line.match /([0-9\.]+%)/
            spare_policy = spare_pct[1];
          end
        end
        # Create storage pools hash
        new storage_pool_info = {
                :name               => "#{pdomain}:#{pool}",
                :pool_name           => pool,
                :ensure             => :present,
                :protection_domain  => pdomain,
                :spare_policy       => spare_policy,
        }
        storage_pool_instances << new(storage_pool_info)
      end
    end
    Puppet.debug('Returning storage pool array')
    storage_pool_instances
  end

  def self.getProtectionDomains
    pdomains = Puppet::Type.type(:scaleio_protection_domain).instances
    pdomains.collect {|x| x.parameters[:name].value}
  end

  def self.prefetch(resources)
    Puppet.debug('Prefetching storage pools')
    Puppet.debug('Prefetching storage pools')
    pool = instances
    resources.keys.each do |name|
      if provider = pool.find{ |poolname| poolname.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    Puppet.debug("Creating storage pool #{@resource[:name]}")
    scli("--add_storage_pool", "--protection_domain_name", @resource[:protection_domain], "--storage_pool_name", @resource[:pool_name])
    updateSparePolicy(@resource[:spare_policy])
		sleep(30)	# wait for rebalance after creating pool
    @property_hash[:ensure] = :present
  end

  def destroy
    scli('--remove_storage_pool', '--protection_domain_name', @resource[:protection_domain], '--storage_pool_name', resource[:pool_name])  # TODO: ask if using property hash for removing is correct (resource not working when using purge)
    @property_hash[:ensure] = :absent
  end

  def spare_policy=(value)
    updateSparePolicy(value)
  end

  def updateSparePolicy(value)
      Puppet.debug("Updating spare policy of pool #{@resource[:name]} to #{value}")
      result = scli('--modify_spare_policy', '--protection_domain_name', @resource[:protection_domain], '--storage_pool_name', @resource[:pool_name], '--spare_percentage', value, '--i_am_sure')
  end

  def exists?
    Puppet.debug("Cecking existence of storage pool #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
