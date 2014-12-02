Puppet::Type.type(:scaleio_protectiondomain).provide(:scaleio_protectiondomain) do

  desc "Manages ScaleIO Protection Domains."

  confine :osfamily => :redhat

  commands :scli => "/var/lib/puppet/module_data/scaleio/scli_wrap"
  
  mk_resource_methods
  
  def self.instances
    Puppet.debug("Puppet::Provider::ScaleIO_PDomain:: got to self.instances.")
    pdomain_instances=[]
    pdomains_info = []
    begin
      pdomain_info = scli("--query_all")
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error Querying Cluster -> #{e.inspect}"
    end
    all_domains = pdomain_info.split("\n")
    pdomain =''    
    # Iterate through the Protection Domain block
    all_domains.each do |pdomains|
      
      # Pull out relevant info
      if pdomains =~/^Protection Domain/
        found_pdomain = pdomains.split(' ')
        pdomain = found_pdomain[2]

        # Create sds instances hash
        new pdomains_info = { 
						:name => pdomain,
						:ensure 	=> :present,
				}
        pdomain_instances << new(pdomains_info)
      end
    end
    # Return the pdomain instances array
    pdomain_instances
  end
    
  
  def self.prefetch(resources)
    Puppet.debug("Puppet::Provider::ScaleIO_PDomain:: Got to self.prefetch")
    pdomains = instances
    resources.keys.each do |name|
      if provider = pdomains.find{ |pdomain| pdomain.name == name }
        resources[name].provider = provider
      end
    end
  end

  
  def create 
    Puppet.debug("Puppet::Provider::ScaleIO_PDomain: Creating Protection Domain #{resource[:name]}")
    begin
      result = scli("--add_protection_domain", "--protection_domain_name", resource[:name])
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error creating Protection Domain #{@resource[:name]} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :present
  end


  def destroy
    Puppet.debug("Puppet::Provider::ScaleIO_PDomain: Destroying Protection Domain #{resource[:name]}")
    begin
      result = scli("--remove_protection_domain", "--protection_domain_name", resource[:name])
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error removing Protection Domain #{@resource[:name]} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :absent
  end
  
  def new_name=(value)
    Puppet.debug("Puppet::Provider::ScaleIO_Pdomain:: Changing Protection Domain name to #{value}")
    begin
      result = scli("--rename_protection_domain", "--protection_domain_name", resource[:name], "--new_name", value)
    rescue Puppet::ExecutionFailure => e
      raise Puppet::Error, "Error renaming Protection Domain #{@resource[:name]} -> #{e.inspect}"
    end
    @property_hash[:ensure] = :present
  end
 
     
  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_PDomain: checking existence of ScaleIO Protection Domain #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
 

end

