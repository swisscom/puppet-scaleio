require 'puppet/parameter/boolean'

Puppet::Type.newtype(:scaleio_fault_set) do
  @doc = "Manage ScaleIO Fault Sets"

  ensurable

  newparam(:name, :namevar => true) do
    desc "Default namevar (composition of 'protection_domain:fault_set')"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for fault set namevar (composition of 'protection_domain:fault_set')." unless value =~ /^[\w\-]+:[\w\-]+$/
    end
  end

  newparam(:fault_set_name, :namevar => true) do
    desc "Name of this fault set, required"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for the name of a fault set." unless value =~ /^[\w\-]+$/
    end
  end

  newparam(:protection_domain, :namevar => true) do
    desc "Name of the protection domain this fault set is a member of, required"
    validate do |value|
      raise ArgumentError, "#{value} is not a valid value for the protection domain of a fault set." unless value =~ /^[\w\-]+$/
    end
  end

  # Our title_patterns method for mapping titles to namevars for supporting composite namevars.
  def self.title_patterns
    identity = lambda {|x| x}
    [
      [
        /^(([^:]*))$/, # name without colons (only fault set name)
        [
          [ :name, identity ],
          [ :fault_set_name, identity ],
        ]
      ],
      [
        /^((.*):(.*))$/, # name with protection domain and fault set name
        [
          [ :name, identity ],
          [ :protection_domain, identity ],
          [ :fault_set_name, identity ],
        ]
      ]
    ]
  end

  autorequire(:scaleio_protection_domain) do
    [ self[:protection_domain] ].compact
  end

end

