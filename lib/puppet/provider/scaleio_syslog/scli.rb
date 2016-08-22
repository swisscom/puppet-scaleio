require 'resolv'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_syslog).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO syslog destinations."

  mk_resource_methods
  
  def self.instances
    Puppet.debug('Getting instances of ScaleIO syslog destinations')
    destinations = []

    query_all = scli("--query_remote_syslog")
    lines = query_all.split("\n")
   
    # Iterate through the syslog destinations
    lines.each do |line|
      if line =~ /Host:/
        destinationInfo = line.match(/Host:\s*([\w\.-]+)\s*Port:\s*([0-9]+)\s*Facility:\s*([0-9]+)/)

        # Create syslog instances hash
        new destination = {
            :name     => Resolv.getaddresses(destinationInfo[1].strip).reject{|i| i =~ Resolv::IPv6::Regex }.sort.first,
            :port     => destinationInfo[2].strip,
            :facility => destinationInfo[3].strip,
            :ensure   => :present,
        }
        destinations << new(destination)
      end
    end

    # Return the syslog destinations array
    destinations
  end
    
  
  def self.prefetch(resources)
    Puppet.debug('Prefetching ScaleIO syslog destinations')
    destinations = instances
    resources.keys.each do |name|
      if provider = destinations.find{ |syslog| syslog.name == name }
        resources[name].provider = provider
      end
    end
  end

  
  def create 
    Puppet.debug("Adding ScaleIO syslog destination #{resource[:name]}")
    reconfigureSyslog(resource[:name], resource[:port], resource[:facility])
    @property_hash[:ensure] = :present
  end


  def port=(value)
    Puppet.debug("Modifying syslog port of #{resource[:name]} to #{value}")
    reconfigureSyslog(resource[:name], value, resource[:facility])
  end


  def facility=(value)
    Puppet.debug("Modifying syslog facility of #{resource[:name]} to #{value}")
    reconfigureSyslog(resource[:name], resource[:port], value)
  end


  def reconfigureSyslog(address, port, facility)
    scli("--stop_remote_syslog", "--remote_syslog_server_ip", address)
    scli("--start_remote_syslog", "--remote_syslog_server_ip", address, "--remote_syslog_server_port", port, "--syslog_facility", facility)
  end


  def destroy
    Puppet.debug("Removing ScaleIO syslog destination #{resource[:name]}")
    scli('--stop_remote_syslog', '--remote_syslog_server_ip', @resource[:name])
    @property_hash[:ensure] = :absent
  end


  def exists?
    Puppet.debug("Checking existence of ScaleIO syslog #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end

