require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_sdc).provide(:scli) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO SDC."

  mk_resource_methods

  def self.instances
    Puppet.debug("Getting SDC instances.")
    sdc_instances = []

    sdcs = scli_query_properties('--object_type', 'SDC', '--all_objects', '--properties', 'NAME,IP,APPROVED')
    sdcs.each do |sdc_id, sdc|
      next if sdc['APPROVED'] =~ /No/i

      sdc_instances << new({
                               :name => sdc['IP'],
                               :ensure => :present,
                               :desc => sdc['NAME'],
                           })
    end

    Puppet.debug("Returning the sdc instances array: #{sdc_instances}")
    sdc_instances
  end

  def self.prefetch(resources)
    Puppet.debug("Prefetching SDC instances")
    sdcs = instances
    resources.keys.each do |name|
      if provider = sdcs.find { |sdcname| sdcname.name == name }
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
