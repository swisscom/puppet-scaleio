Puppet::Type.newtype(:scaleio_storage_pool) do
  @doc = "Manage ScaleIO Storage Pools"

  ensurable

  newparam(:name, :namevar => true) do
    desc "The Storage Pool name"
    validate do |value|
      fail("Puppet::Type::ScaleIO_StoragePool:: #{value} is not a valid value for Storage Pool name.") unless value =~ /^[ -~]+$/
    end
  end

  newproperty(:new_name) do
    desc "The new Storage Pool name"  
    validate do |value|
      fail("Puppet::Type::ScaleIO_StoragePool:: #{value} is not a valid value for new Storage Pool name.") unless value =~ /^[ -~]+$/
    end
  end

  newproperty(:protection_domain) do
    desc "The Protection Domain name the Storage Pool belongs to."
  end

  newproperty(:spare_policy) do
    desc "The Storage Pool spare capacity"
  end

  autorequire(:scaleio_protection_domain) do
    [ self[:protection_domain] ].compact
  end
end

