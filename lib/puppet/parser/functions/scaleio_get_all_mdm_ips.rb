module Puppet::Parser::Functions
  newfunction(:scaleio_get_all_mdm_ips, :type => :rvalue, :doc => <<-EOS
Extract all IPs of the MDM or TB hash. Example:
      scaleio_get_all_mdm_ips(
                            {
                                'Name1' => {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                'Name2' => {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                'Name3' => {'ips' => ['10.0.0.3', '10.0.0.20'], 'mgmt_ips' => '11.0.0.3'},
                            },
                            'ips']
      )

      Returns the following array:
      ['10.0.0.1', '10.0.0.2', '10.0.0.3', '10.0.0.20']
  EOS
  ) do |arguments|

    raise(Puppet::ParseError, "scaleio_get_all_mdm_ips(): Wrong number of arguments " +
        "given (#{arguments.size} for 2)") if arguments.size != 2

    Puppet::Parser::Functions.autoloader.load(:scaleio_get_all_mdm_ips) \
      unless Puppet::Parser::Functions.autoloader.loaded?(:scaleio_get_all_mdm_ips)

    data = arguments[0]
    key = arguments[1]

    data.values.map{|x| x[key]}.flatten()

  end
end
