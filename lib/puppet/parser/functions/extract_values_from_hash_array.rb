module Puppet::Parser::Functions
  newfunction(:extract_values_from_hash_array, :type => :rvalue, :doc => <<-EOS
Extract values out of an array of hashes. Example:
      extract_values_from_hash_array(
                            [
                                {'ips' => '10.0.0.1', 'mgmt_ips' => '11.0.0.1'},
                                {'ips' => '10.0.0.2', 'mgmt_ips' => '11.0.0.2'},
                                {'ips' => '10.0.0.3', 'mgmt_ips' => '11.0.0.3'},
                            ],
                            'ips']
      )

      Returns the following array:
      ['10.0.0.1', '10.0.0.2', '10.0.0.3']
  EOS
  ) do |arguments|

    raise(Puppet::ParseError, "extract_values_from_hash_array(): Wrong number of arguments " +
        "given (#{arguments.size} for 2)") if arguments.size != 2

    Puppet::Parser::Functions.autoloader.load(:extract_values_from_hash_array) \
      unless Puppet::Parser::Functions.autoloader.loaded?(:extract_values_from_hash_array)

    data = arguments[0]
    key = arguments[1]

    data.map{|x| x[key].is_a?(Array) ? x[key][0] : x[key]}

  end
end
