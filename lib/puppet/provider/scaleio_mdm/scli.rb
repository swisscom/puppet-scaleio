#require 'puppet/provider/blocker'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_mdm).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO MDM's."

  confine :osfamily => :redhat

  mk_resource_methods


  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    Puppet.debug('Getting MDM instances.')

    mdm_instances=[]
    mdms = scli_query_properties('--object_type', 'MDM', '--all_objects', '--preset', 'ALL')

    # Iterate through each MDM block
    mdms.each do |mdm_id, mdm|
      if mdm['NAME'] =~ /N\/A/i
        raise Puppet::Error, "ScaleIO MDM (#{mdm_id}) without a name is not supported by the puppet module, please give it a name manually."
      end
      mdm_instances << new({
                               :name => mdm['NAME'],
                               :ensure => :present,
                               :ips => mdm['IPS'].split(','),
                               :mgmt_ips => mdm['MGMT_IPS'].split(','),
                               :is_tiebreaker => mdm['ROLE'] !~ /^MDM_ROLE_MANAGER/i,
                           })
    end

    # Return the MDM array
    Puppet.debug("Returning the MDM instances array.")
    mdm_instances
  end

  def self.prefetch(resources)
    Puppet.debug("Prefetching MDM instances")
    mdms = instances
    resources.keys.each do |name|
      if provider = mdms.find { |mdmname| mdmname.name == name }
        resources[name].provider = provider
      end
    end
  end

  def mgmt_ips=(mgmt_ips)
    scli('--modify_management_ip', '--target_mdm_name', resource[:name], '--new_mdm_management_ip', mgmt_ips.join(','))
  end

  def create
    args = ['--add_standby_mdm', '--new_mdm_ip', resource[:ips].join(','), '--new_mdm_name', resource[:name], '--mdm_role', resource[:is_tiebreaker] ? 'tb' : 'manager']
    if resource[:mgmt_ips] && !resource[:mgmt_ips].empty?
      args << '--new_mdm_management_ip' << resource[:mgmt_ips].join(',')
    end
    scli(*args)
    @property_hash[:ensure] = :present
  end

  def destroy
    #Puppet.debug "Can only remove  a ScaleIO MDM (#{resource[:name]}) takes two Puppet runs."
    scli('--remove_standby_mdm', '--remove_mdm_name', resource[:name])
    @property_hash[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Checking existence of ScaleIO MDM #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end

  def ips=(ips)
    raise Puppet::Error, "Changing ScaleIO MDM IPs (#{resource[:name]}) is not supported by the puppet module."
  end

  def is_tiebreaker=(value)
    raise Puppet::Error, "Changing ScaleIO MDM (to/from MDM/TB) (#{resource[:name]}) is not supported by the puppet module."
  end
end
