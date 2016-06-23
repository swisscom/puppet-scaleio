#require 'puppet/provider/blocker'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_mdm_cluster).provide(:scaleio_mdm_cluster) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO MDM cluster."

  confine :osfamily => :redhat

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    Puppet.debug('Getting MDM cluster info.')

    mdm_names = []
    tb_names = []
    mdms = scli_query_properties('--object_type', 'MDM', '--all_objects', '--preset', 'ALL')

    # Iterate through each MDM block
    mdms.each do |mdm_id, mdm|
      if mdm['NAME'] =~ /N\/A/i
        raise Puppet::Error, "ScaleIO MDM (#{mdm_id}) without a name is not supported by the puppet module, please give it a name manually."
      end
      if mdm['ROLE'] =~ /^MDM_ROLE_MANAGER/i and mdm['IS_STANDBY'] =~ /^NO/i
        mdm_names << mdm['NAME']
      elsif mdm['ROLE'] =~ /^MDM_ROLE_TIE_BREAKER/i and mdm['IS_STANDBY'] =~ /^NO/i
        tb_names << mdm['NAME']
      end
    end

    mdm_cluster = []
    mdm_cluster << new({
                      :name => 'mdm_cluster',
                      :ensure => :present,
                      :mdm_names => mdm_names,
                      :tb_names => tb_names,
                  })

    # Return the MDM array
    Puppet.debug("Returning the MDM cluster array: #{mdm_cluster}")
    mdm_cluster
  end

  def self.prefetch(resources)
    Puppet.debug("Prefetching MDM cluster")
    mdm_cluster = instances
    resources.keys.each do |name|
      if provider = mdm_cluster.find { |clustername| clustername.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    Puppet.debug('Flusing MDM cluster config')
    if @property_flush and ! @property_flush.empty?
      add_mdms = @property_flush[:mdm_names] - @property_hash[:mdm_names]
      remove_mdms = @property_hash[:mdm_names] - @property_flush[:mdm_names]
      add_tbs = @property_flush[:tb_names] - @property_hash[:tb_names]
      remove_tbs = @property_hash[:tb_names] - @property_flush[:tb_names]

      Puppet.debug(add_mdms)
      Puppet.debug(remove_mdms)
      Puppet.debug(add_tbs)
      Puppet.debug(remove_tbs)

      member_count = @property_flush[:mdm_names].length + @property_flush[:tb_names].length

      Puppet.debug(member_count)

      if "#{member_count}" !~ /^[135]$/
        raise Puppet::Error, "A ScaleIO MDM cluster must have 1, 3 or 5 members, defined: #{member_count}."
      end

      args = ['--switch_cluster_mode', '--cluster_mode', "#{member_count}_node"]

      args << '--add_slave_mdm_name' << add_mdms.join(',') if !add_mdms.empty?
      args << '--remove_slave_mdm_name' << remove_mdms.join(',') if !remove_mdms.empty?
      args << '--add_tb_name' << add_tbs.join(',') if !add_tbs.empty?
      args << '--remove_tb_name' << remove_tbs.join(',') if !remove_tbs.empty?

      scli(*args)
    end
  end

  def tb_names=(tb_names)
    @property_flush[:tb_names] = tb_names
  end

  def mdm_names=(mdm_names)
    @property_flush[:mdm_names] = mdm_names
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    raise Puppet::Error, "A ScaleIO MDM cluster cannot be destroyed ;-)"
    #@property_flush[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Checking existence of ScaleIO MDM cluster")
    @property_hash[:ensure] == :present
  end
end