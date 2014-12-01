Puppet::Type.newtype(:scaleio_protectiondomain) do
  @doc = "Manage ScaleIO Protection Domains"
  
  ensurable

  newparam(:name, :namevar => true) do
    desc "The Protection Domain name"
    validate do |value|
      fail("Puppet::Type::ScaleIO_PDomain:: #{value} is not a valid value for Protection Domain name.") unless value =~ /^[ -~]+$/
    end
  end
  
  newproperty(:new_name) do
    desc "The new Protection Domain name"  
    validate do |value|
      fail("Puppet::Type::ScaleIO_PDomain:: #{value} is not a valid value for new Protection Domain name.") unless value =~ /^[ -~]+$/
    end
  end 
  
  newproperty(:capacity) do
    desc "The Protection Domain capacity"
  end
  
end    
