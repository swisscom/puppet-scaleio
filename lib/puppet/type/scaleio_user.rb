Puppet::Type.newtype(:scaleio_user) do
  @doc = "Manage ScaleIO users"
  
  ensurable

  validate do
    validate_required(:role, :password)
  end

  newparam(:name, :namevar => true) do
    desc "The user name."
    validate do |value|
      fail("#{value} is not a valid value for a user name.") unless value =~ /^[\w]+$/
    end
  end

  newparam(:password) do
    desc "The password for the mdm user."
    validate do |value|
      fail("Password must be provided") unless value =~ /^[\w]+$/
    end
  end

  newproperty(:role) do
    desc "The user role"
    validate do |value|
      fail("#{value} is not a valid role (must be one of Monitor, Configure, Administrator).") unless value =~ /^(Monitor|Configure|Administrator)$/
    end
  end

  newproperty(:change_password) do
    desc "true if the password needs to be reset"
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

