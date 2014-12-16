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
  end

  def scli(*args)
    self.class.scli(args)
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.commands :scli_wrap => '/var/lib/puppet/module_data/scaleio/scli_wrap'
  end
end
