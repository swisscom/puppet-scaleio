require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_sdc_name).provide(:scaleio_sdc_name) do 
  include Puppet::Provider::Scli

  desc "Manages ScaleIO SDC names."

  confine :osfamily => :redhat

  mk_resource_methods
  
  def self.instances
    Puppet.debug("Getting SDC name instances.")
    sdc_name_instances=[]
    query_all_sdc_lines = scli('--query_all_sdc').split("\n")
    
    # Iterate through each SDS block
    query_all_sdc_lines.each do |line|
      next if line !~/SDC ID/

      # Get information about the SDC
      name = line.match(/Name:(.*)IP/m)[1].strip
      ip = line.match(/IP:(.*)State/m)[1].strip

      next if name =~ /^N\/A$/

      # Create sdc name instances hash
      new sdc_name_instance = { 
        :name => ip,
        :ensure => :present,
        :desc => name,
      }

      sdc_name_instances << new(sdc_name_instance)
    end
    
    # Return the SDS array
    Puppet.debug("Returning the SDC name instances array.")
    sdc_name_instances
  end
  
  def self.prefetch(resources)
    Puppet.debug("Prefetching SDC instances")
    sds = instances
    resources.keys.each do |name|
      if provider = sds.find{ |sdsname| sdsname.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create 
    Puppet.debug("Creating SDC name #{@resource[:name]}")
    rename_sdc(@resource[:desc])
    @property_hash[:ensure] = :present
  end

  # TODO: should set the name (desc) to nothing, unfortunately not (yet?) possible
  def destroy
    Puppet.debug("Destroying SDC name #{@resource[:name]} - not yet implemented")
    raise Puppet::Error, "Destroying (unmapping) an SDC name from an IP is not (yet?) supported by ScaleIO"
    #@property_hash[:ensure] = :absent
  end
  
  def desc=(value)
    Puppet.debug("Renaming SDC #{@resource[:name]}")
    rename_sdc(value)
  end

  def rename_sdc(value)
    scli('--rename_sdc', '--sdc_ip', @resource[:name], '--new_name', value)
  end

  def exists?
    Puppet.debug("Puppet::Provider::ScaleIO_SDS: checking existence of ScaleIO SDS #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end
