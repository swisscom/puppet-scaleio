require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_user).provide(:scaleio_user) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO users."

  confine :osfamily => :redhat

  commands :add_scaleio_user => '/var/lib/puppet/module_data/scaleio/add_scaleio_user'

  mk_resource_methods
  
  def self.instances
    Puppet.debug('Getting instances of ScaleIO users')
    users = []
    user = {}

    query_all = scli("--query_users")
    lines = query_all.split("\n")
   
    # Iterate through the users
    userBlockStarted = false
    lines.each do |line|
      if userBlockStarted
         userInfo = line.match(/^([\w]+)\s+([\w]+)\s+([\w]+)\s+([\w]+)\s*/)  #ID, role, need new pw, user name

        # Create user instances hash
        new user = { 
            :name     => userInfo[4].strip,
            :role     => userInfo[2].strip,
            :ensure   => :present,
        }
        users << new(user)
      end

      # users are listed below the line containing '-------------'
      if line =~/^----------------/
        userBlockStarted = true
      end
    end

    # Return the user instances array
    users
  end
    
  
  def self.prefetch(resources)
    Puppet.debug('Prefetching ScaleIO users')
    users = instances
    resources.keys.each do |name|
      if provider = users.find{ |user| user.name == name }
        resources[name].provider = provider
      end
    end
  end

  
  def create 
    Puppet.debug("Creating ScaleIO user #{resource[:name]}")
    add_scaleio_user(resource[:name], resource[:role], resource[:password])
    @property_hash[:ensure] = :present
  end


  def destroy
    Puppet.debug("Removing ScaleIO user #{resource[:name]}")
    scli('--delete_user', '--username', @resource[:name])
    @property_hash[:ensure] = :absent
  end


  def exists?
    Puppet.debug("Checking existence of ScaleIO user #{@resource[:name]}")
    @property_hash[:ensure] == :present
  end
end

