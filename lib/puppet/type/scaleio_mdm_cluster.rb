require 'puppet/parameter/boolean'

Puppet::Type.newtype(:scaleio_mdm_cluster) do
  @doc = "Manage a ScaleIO MDM cluster"

  ensurable

  validate do
    validate_required(:mdm_names, :tb_names)
  end

  newparam(:name, :namevar => true) do
    desc 'The MDM name'
    validate do |value|
      fail("scaleio_mdm_cluster name must be mdm_cluster, to ensure that there is always only one scaleio_mdm_cluster resource") unless value == 'mdm_cluster'
    end
  end

  newproperty(:mdm_names, :array_matching => :all) do
    desc 'The MDM names that shall be active in the MDM cluster'
    validate do |value|
      fail("#{value} is not a valid MDM cluster name (word character and hyphen).") unless value =~ /^[\w\-]+$/
    end
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:tb_names, :array_matching => :all) do
    desc 'The TB names that shall be active in the MDM cluster'
    validate do |value|
      fail("#{value} is not a valid MDM cluster name (word character and hyphen).") unless value =~ /^[\w\-]+$/
    end
    def insync?(is)
      is.sort == should.sort
    end
  end

  # helper method, pass required parameters
  def validate_required(*required_parameters)
    if self[:ensure] == :present
      required_parameters.each do |req_param|
        raise ArgumentError, "parameter '#{req_param}' is required" if self[req_param].nil?
      end
    end
  end
end