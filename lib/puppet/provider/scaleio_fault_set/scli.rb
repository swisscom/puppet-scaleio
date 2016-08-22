require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_fault_set).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO Fault Set."

  confine :osfamily => :redhat

  mk_resource_methods

  def self.instances
    Puppet.debug('getting instances of fault sets')

    # get protection domains to lookup the name by the id
    pdos = scli_query_properties('--object_type', 'PROTECTION_DOMAIN', '--all_objects', '--properties', 'NAME')

    fault_set_instances = []

    fault_sets = scli_query_properties('--object_type', 'FAULT_SET', '--all_objects', '--properties', 'NAME,PROTECTION_DOMAIN_ID')
    fault_sets.each do |fault_set_id, fault_set|
      pdomain = pdos[fault_set['PROTECTION_DOMAIN_ID']]['NAME']

      fault_set_instances << new({
                                :name               => "#{pdomain}:#{fault_set['NAME']}",
                                :fault_set_name     => fault_set['NAME'],
                                :ensure             => :present,
                                :protection_domain  => pdomain,
                               })
    end

    Puppet.debug("Returning the fault set instances array: #{fault_set_instances}")
    fault_set_instances
  end

   def self.prefetch(resources)
    Puppet.debug('Prefetching fault sets')
    fault_sets = instances
    resources.keys.each do |name|
      if provider = fault_sets.find{ |faultset| faultset.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    Puppet.debug("Creating fault set #{@resource[:name]}")
    scli("--add_fault_set", "--protection_domain_name", @resource[:protection_domain], "--fault_set_name", @resource[:fault_set_name])

    @property_hash[:ensure] = :present
  end

  def destroy
    scli('--remove_fault_set', '--protection_domain_name', @resource[:protection_domain], '--fault_set_name', resource[:fault_set_name])
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Cecking existence of fault set #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
