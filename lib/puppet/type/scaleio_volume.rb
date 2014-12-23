Puppet::Type.newtype(:scaleio_volume) do
  @doc = "Manage ScaleIO volume's"

  ensurable

  validate do
    validate_required(:storage_pool, :protection_domain, :size, :type)
  end

  newparam(:name, :namevar => true) do
    desc "The volume name"
    validate do |value|
      fail("#{value} is not a valid value for volume name.") unless value =~ /^[\w\-]+$/
    end
  end

  newparam(:storage_pool) do
    desc "The name of the storage pool"
    validate do |value|
      fail("#{value} is not a valid storag pool name") unless value =~ /^[\w\-]+$/
    end
  end

  newparam(:protection_domain) do
    desc "The name of the protection domain"
    validate do |value|
      fail("#{value} is not a valid protection domain name") unless value =~ /^[\w\-]+$/
    end
  end

  newproperty(:size) do
    desc "The size in GB of the volume"
    validate do |value|
      fail("#{value} is not a valid size must be an integer and a multiple of 8") unless value.is_a? Integer and value % 8 == 0
    end
  end

  newproperty(:type) do
    desc "The type of the volume (thin|thick)"
    validate do |value|
      fail("#{value} type must be either thin or thick") unless value =~ /^(thin|thick)$/
    end
  end

  newproperty(:sdc_nodes, :array_matching => :all) do
    desc "The names of the SDC nodes this volume shall be mapped to"
    validate do |value|
      fail("#{value} is not a valid SDC name") unless value =~ /^[\w\-]+$/
    end
    def insync?(is)
      is.sort == should.sort
    end
  end

  autorequire(:scaleio_protection_domain) do
    [ self[:protection_domain] ].compact
  end

  autorequire(:scaleio_storage_pool) do
    [ "#{self[:protection_domain]}:#{self[:storage_pool]}" ].compact
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

