require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_sdc).provide(:scaleio_sdc) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO SDC."

  confine :osfamily => :redhat

  mk_resource_methods
  
  def self.instances
    Puppet.debug("Getting SDC instances.")
    sdc_instances=[]
    query_all_sdc_lines = scli('--query_all_sdc').split("\n")
    
    # Iterate through each SDS block
    query_all_sdc_lines.each do |line|
      next if line !~/SDC ID/
      next if line =~/Approved: no/

      # Get information about the SDC
      name = line.match(/Name:(.*)IP/m)[1].strip
      ip = line.match(/IP:(.*)State/m)[1].strip

      # next if name =~ /^N\/A$/

      # Create sdc instances hash
      new sdc_instance = {
        :name => ip,
        :ensure => :present,
        :desc => name,
      }

      sdc_instances << new(sdc_instance)
    end
    
    # Return the SDS array
    Puppet.debug("Returning the SDC instances array.")
    sdc_instances
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
    Puppet.debug("Adding SDC #{@resource[:name]}")
    scli('--add_sdc', '--sdc_ip', @resource[:name], '--sdc_name', @resource[:desc])
    @property_hash[:ensure] = :absent
  end

  def destroy
    Puppet.debug("Removing SDC #{@resource[:name]}")
    scli('--remove_sdc', '--sdc_ip', @resource[:name])
    @property_hash[:ensure] = :absent
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
