require 'puppet/parameter/boolean'

Puppet::Type.newtype(:scaleio_storage_pool) do
  @doc = "Manage ScaleIO Storage Pools"

  ensurable

  validate do
    validate_required(:spare_policy, :ramcache)
  end

  newparam(:name, :namevar => true) do
    desc "Default namevar (composition of 'protection_domain:storage_pool')"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for storage pool namevar (composition of 'protection_domain:storage_pool')." unless value =~ /^[\w\-]+:[\w\-]+$/
    end
  end

  newparam(:pool_name, :namevar => true) do
    desc "Name of this pool, required"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for the name of a storage pool." unless value =~ /^[\w\-]+$/
    end
  end

  newparam(:protection_domain, :namevar => true) do
    desc "Name of the protection domain this pool is a member of, required"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for the protection domain of a pool." unless value =~ /^[\w\-]+$/
    end
  end

  newproperty(:spare_policy) do
    desc "The storage pool spare capacity"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for the storage pool spare capacity (f.e. 34%)." unless value =~ /^[0-9]{1,2}%$/
    end
  end

  newproperty(:ramcache) do
    desc "Enable RAM read cache for this pool?"
    validate do |value|
      raise ArgumentError, "RAM cache for storage pool can either be enabled or disabled (true/false)." unless value =~ /^enabled|disabled$/
    end
    defaultto 'enabled'
  end

  newproperty(:device_scanner_mode) do
    desc "Mode of the background device scanner (disabled|device_only|data_comparison). Default: device_only"
    validate do |value|
      raise ArgumentError, "Valid values for storage pool device scanner mode: disabled|device_only|data_comparison." unless value =~ /^disabled|device_only|data_comparison$/
    end
    defaultto 'device_only'
  end

  newproperty(:device_scanner_bandwidth) do
    desc "Bandwidth limit of the background device scanner. Default: 1024KB"

    defaultto '1024KB'
  end

  # This is a parameter as zeropadding, as updating zero padding is no more allowed once the pool has devices 
  newparam(:zeropadding, :boolean => true) do
    desc "Should zero padding be enabled?"

    defaultto true
  end

  # Our title_patterns method for mapping titles to namevars for supporting composite namevars.
  def self.title_patterns
    identity = lambda {|x| x}
    [
      [
        /^(([^:]*))$/, # name without colons (only pool name)
        [
          [ :name, identity ],
          [ :pool_name, identity ],
        ]
      ],
      [
        /^((.*):(.*))$/, # name with protection domain and pool name
        [
          [ :name, identity ],
          [ :protection_domain, identity ],
          [ :pool_name, identity ],
        ]
      ]
    ]
  end

  autorequire(:scaleio_protection_domain) do
    [ self[:protection_domain] ].compact
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

