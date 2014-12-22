Puppet::Type.newtype(:scaleio_sdc_name) do
  @doc = "Manage ScaleIO SDC names"

  ensurable

  validate do
    validate_required(:desc)
  end

  newparam(:name, :namevar => true) do
    desc "The SDC IP"
    validate do |value|
      fail("#{value} is not a valid SDC IPv4 address") unless IPAddr.new(value).ipv4?
    end
  end

  newproperty(:desc) do
    desc "The name of the SDC"
    validate do |value|
      fail("#{value} is not a valid value for an SDC name.") unless value =~ /^[\w\-]+$/
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

