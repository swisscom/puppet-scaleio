require 'puppet/parameter/boolean'

Puppet::Type.newtype(:scaleio_mdm) do
  @doc = "Manage ScaleIO MDM's"

  ensurable

  validate do
    validate_required(:ips, :is_tiebreaker)
  end

  newparam(:name, :namevar => true) do
    desc 'The MDM name'
    validate do |value|
      fail("#{value} is not a valid MDM name (word character and hyphen).") unless value =~ /^[\w\-]+$/
    end
  end

  newproperty(:ips, :array_matching => :all) do
    desc 'The MDM IP address/addresses'
    validate do |value|
      fail("#{value} is not a valid IPv4 address") unless IPAddr.new(value).ipv4?
    end
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:mgmt_ips, :array_matching => :all) do
    desc 'The MDM management IP address/addresses'
    validate do |value|
      fail("#{value} is not a valid IPv4 address") unless IPAddr.new(value).ipv4?
    end
    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:is_tiebreaker, :boolean => true) do
    desc 'Is it a tiebreaker or a MDM'

    defaultto false
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

