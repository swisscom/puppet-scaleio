Puppet::Type.newtype(:scaleio_protection_domain) do
	@doc = "Manage ScaleIO Protection Domains"
  
  ensurable

  newparam(:name, :namevar => true) do
    desc "The Protection Domain name"
    validate do |value|
      fail("Puppet::Type::scaleio_protection_domain:: #{value} is not a valid value for Protection Domain name.") unless value =~ /^[\w\-]+$/
    end
  end
  
  newproperty(:new_name) do
    desc "The new Protection Domain name"  
    validate do |value|
      fail("Puppet::Type::scaleio_protection_domain:: #{value} is not a valid value for new Protection Domain name.") unless value =~ /^[\w\-]+$/
    end
  end 
end    
