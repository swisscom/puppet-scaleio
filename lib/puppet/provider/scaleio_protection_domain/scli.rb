require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_protection_domain).provide(:scaleio_protection_domain) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO Protection Domains."

  confine :osfamily => :redhat

  mk_resource_methods
  
  def self.instances
    Puppet.debug('Getting instances of protection domains')
    pdomain_instances = []

    pdos = scli_query_properties('--object_type', 'PROTECTION_DOMAIN', '--all_objects', '--properties', 'NAME')
    pdos.each do |pdo_id, pdo|
      if pdo['NAME'] =~ /N\/A/i
        raise Puppet::Error, "ScaleIO protection domain (#{pdo_id}) without a name is not supported by the puppet module, please give it a name manually."
      end
      pdomain_instances << new({
                               :name => pdo['NAME'],
                               :ensure => :present,
                           })
    end

    Puppet.debug("Returning the protection domain instances array: #{pdomain_instances}")
    pdomain_instances
  end
    
  
  def self.prefetch(resources)
    Puppet.debug('Prefetching protection domains')
    pdomains = instances
    resources.keys.each do |name|
      if provider = pdomains.find{ |pdomain| pdomain.name == name }
        resources[name].provider = provider
      end
    end
  end

  
  def create 
    Puppet.debug("Creating protection domain #{resource[:name]}")
    scli("--add_protection_domain", "--protection_domain_name", resource[:name])
    @property_hash[:ensure] = :present
  end


  def destroy
    Puppet.debug("Removing protection domain #{resource[:name]}")
    result = scli("--remove_protection_domain", "--protection_domain_name", resource[:name])
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    Puppet.debug("Checking existence of protection domain #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end

