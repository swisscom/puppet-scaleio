Puppet::Type.newtype(:scaleio_protection_domain) do
  @doc = "Manage ScaleIO Protection Domains"
  
  ensurable

  newparam(:name, :namevar => true) do
    desc "The Protection Domain name"
    validate do |value|
      fail("#{value} is not a valid value for a protection domain name.") unless value =~ /^[\w\-]+$/
    end
  end
end    
