Puppet::Type.type(:scaleio_protection_domain).provide(:scaleio_protection_domain) do

  desc "Manages ScaleIO Protection Domains."

  confine :osfamily => :redhat

  commands :scli => "/var/lib/puppet/module_data/scaleio/scli_wrap"
  
  mk_resource_methods
  
  def self.instances
    Puppet.debug('Getting instances of protection domains')
    pdomain_instances = []
    pdomain_info = {}
    begin
      query_all = scli("--query_all")
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error Querying Cluster -> #{e.inspect}"
    end
    lines = query_all.split("\n")
    pdomain =''    
    # Iterate through the Protection Domain block
    lines.each do |line|
      
      # Pull out relevant info
      if line =~/^Protection Domain/
        pdomain = line.split(' ')[2]

        # Create pdomains instances hash
        new pdomain_info = { 
						:name     => pdomain,
						:ensure 	=> :present,
				}
        pdomain_instances << new(pdomain_info)
      end
    end
    # Return the pdomain instances array
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
    begin
      result = scli("--add_protection_domain", "--protection_domain_name", resource[:name])
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error creating Protection Domain #{@resource[:name]} -> #{e.inspect}"
		end
    @property_hash[:ensure] = :present
  end


  def destroy
    Puppet.debug("Removing protection domain #{resource[:name]}")
		begin
      result = scli("--remove_protection_domain", "--protection_domain_name", resource[:name])
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error removing Protection Domain #{@resource[:name]} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :absent
  end
  
  def exists?
    Puppet.debug("Checking existence of protection domain #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
 

end

