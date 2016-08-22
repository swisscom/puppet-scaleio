require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_storage_pool).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO Storage Pool."

  confine :osfamily => :redhat

  commands :sleep => 'sleep'

  mk_resource_methods

  def self.instances
    Puppet.debug('getting instances of storage pools')

    # get protection domains to lookup the name by the id
    pdos = scli_query_properties('--object_type', 'PROTECTION_DOMAIN', '--all_objects', '--properties', 'NAME')

    pool_instances = []

    pools = scli_query_properties('--object_type', 'STORAGE_POOL', '--all_objects', '--properties', 'NAME,SPARE_PERCENT,USE_RMCACHE,PROTECTION_DOMAIN_ID')
    pools.each do |pool_id, pool|
      pdomain = pdos[pool['PROTECTION_DOMAIN_ID']]['NAME']

      pool_instances << new({
                                :name               => "#{pdomain}:#{pool['NAME']}",
                                :pool_name          => pool['NAME'],
                                :ensure             => :present,
                                :protection_domain  => pdomain,
                                :spare_policy       => pool['SPARE_PERCENT'],
                                :ramcache           => pool['USE_RMCACHE'] =~ /^Yes$/i ? 'enabled' : 'disabled',
                               })
    end

    Puppet.debug("Returning the storage pool instances array: #{pool_instances}")
    pool_instances
  end

   def self.prefetch(resources)
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
    update_ramcache(@resource[:ramcache])

    # Should zero padding be enabled?
    if @resource[:zeropadding]
      enable_zeropadding()
    end

    sleep(30)  # wait for rebalance after creating pool
    @property_hash[:ensure] = :present
  end

  def destroy
    scli('--remove_storage_pool', '--protection_domain_name', @resource[:protection_domain], '--storage_pool_name', resource[:pool_name])  # TODO: ask if using property hash for removing is correct (resource not working when using purge)
    @property_hash[:ensure] = :absent
  end

  def ramcache=(value)
    update_ramcache(value)
  end

  def update_ramcache(value)
    Puppet.debug("Updating ramcache setting of pool #{@resource[:name]} to #{value}")
    scli("--set_rmcache_usage", "--protection_domain_name", @resource[:protection_domain], "--storage_pool_name", @resource[:pool_name], "--i_am_sure", if value == 'enabled' then "--use_rmcache" else "--dont_use_rmcache" end)
  end

  def spare_policy=(value)
    updateSparePolicy(value)
  end

  def updateSparePolicy(value)
    Puppet.debug("Updating spare policy of pool #{@resource[:name]} to #{value}")
    result = scli('--modify_spare_policy', '--protection_domain_name', @resource[:protection_domain], '--storage_pool_name', @resource[:pool_name], '--spare_percentage', value, '--i_am_sure')
  end

  def enable_zeropadding()
    scli("--modify_zero_padding_policy", "--protection_domain_name", @resource[:protection_domain], "--storage_pool_name", @resource[:pool_name], "--enable_zero_padding")
  end

  def exists?
    Puppet.debug("Cecking existence of storage pool #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
