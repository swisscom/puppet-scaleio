require 'resolv'
Puppet::Type.newtype(:scaleio_syslog) do
  @doc = "Manage ScaleIO syslogs"
  
  ensurable

  validate do
    validate_required(:port, :facility)
  end

  newparam(:name, :namevar => true) do
    desc "The syslog destination address."
    validate do |value|
      fail("#{value} is not a valid syslog destination.") unless value =~ /^[\w\.\-]+$/
    end
    munge do |value|
      Resolv.getaddresses(value).reject{|i| i =~ Resolv::IPv6::Regex }.sort.first
    end
  end

  newproperty(:port) do
    desc "The destination port"
    validate do |value|
      fail("Syslog destination port must be a number") unless value =~ /^[0-9]+$/
    end
  end

  newproperty(:facility) do
    desc "The syslog facility (1-16)"

    defaultto "16"

    validate do |value|
      fail("#{value} is not a valid syslog facility (must be 1-16).") unless value =~ /^([1-9]|10|11|12|13|14|15|16)$/
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
