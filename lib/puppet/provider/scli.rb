require 'socket'
require 'timeout'

module Puppet::Provider::Scli

  module ClassMethods
    def scli(*args)
      begin
        result = scli_wrap(args)
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error, "scli command #{args} had an error -> #{e.inspect}"
      end
      result
    end

    def scli_query_properties(*args)
      Puppet.debug("Querying scaleio properties #{args}")
      query_result = scli('--query_properties', args).split("\n")
      group_name = ''
      properties = {}

      query_result.each do |line|
        if line =~ /^([^\s]+)\s([^:]+)/
          group_name = $2
          properties[group_name] = Hash.new { |hash, key| hash[key] = {} }
        else
          line =~ /^\s+([^\s]+)\s+(.*)$/
          properties[group_name][$1] = $2
        end
      end
      Puppet.debug("Queried scaleio properties #{properties}")
      properties
    end

    # From gist: https://gist.github.com/ashrithr/5305786
    def port_open?(ip, port, seconds=1)
      # => checks if a port is open or not on a remote host
      Timeout::timeout(seconds) do
        begin
          TCPSocket.new(ip, port).close
          true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
          false
        end
      end
    rescue Timeout::Error
      false
    end

    # Increment the consul key by 1, until max_tries is reached.
    # If max_tries is reached, Puppet run will fail
    def consul_max_tries(key, max_tries)
      consul_kv = Puppet::Type.type(:consul_kv).new(
          :name => "#{key}",
          :value => '1').provider
      tries = consul_kv.send('value') # retrive current try value

      tries = tries.empty? ? 1 : tries.to_i + 1
      if (tries >= max_tries)
        raise Puppet::Error, "Reached max_tries (#{tries}) for #{key}"
      end

      Puppet.debug("ScaleIO #{key} incrementing try number to #{tries}")

      # Update the key
      consul_kv = Puppet::Type.type(:consul_kv).new(
          :name => "#{key}",
          :value => "#{tries}").provider
      consul_kv.send('create')
      Puppet.debug("Key should be here")
    end

    def consul_delete_key(key)
      Puppet.debug("ScaleIO #{key} removing consul key #{key}")
      consul_kv = Puppet::Type.type(:consul_kv).new(
          :name => "#{key}",
          :value => '1').provider
      tries = consul_kv.send('destroy') # retrive current try value
    end
  end

  def scli(*args)
    self.class.scli(args)
  end

  def scli_query_properties(*args)
    self.class.scli_query_properties(args)
  end

  def port_open?(ip, port, seconds=1)
    self.class.port_open?(ip, port, seconds)
  end

  def consul_max_tries(key, max_tries)
    self.class.consul_max_tries(key, max_tries)
  end

  def consul_delete_key(key)
    self.class.consul_delete_key(key)
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.commands :scli_wrap => '/opt/emc/scaleio/scripts/scli_wrap.sh'
    base.commands :scli_basic => '/bin/scli'
  end
end
