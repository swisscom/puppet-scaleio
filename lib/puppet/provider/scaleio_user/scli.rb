require File.expand_path(File.join(File.dirname(__FILE__), '..', 'scli'))
Puppet::Type.type(:scaleio_user).provide(:scaleio_user) do
  include Puppet::Provider::Scli

  desc "Manages ScaleIO users."

  confine :osfamily => :redhat

  commands :add_scaleio_user => '/opt/emc/scaleio/scripts/add_scaleio_user.sh'

  commands :change_scaleio_password =>
               '/opt/emc/scaleio/scripts/change_scaleio_password.sh'

  mk_resource_methods
  
  def self.instances
    Puppet.debug('Getting instances of ScaleIO users')
    users = []
    user = {}

    query_all = scli("--query_users")
    lines = query_all.split("\n")
   
    # Iterate through the users
    user_block_started = false
    lines.each do |line|
      if user_block_started
         user_info = line.match(/^([\w]+)\s+([\w]+)\s+([\w]+)\s+([\w]+)\s*/)  #ID, role, need new pw, user name
         username = user_info[4].strip
         role = user_info[2].strip

        Puppet.debug(username)

        # Create user instances hash
        new user = { 
            :name           => username,
            :role           => role,
            :need_pw_change => false,
            :ensure         => :present,
        }
        users << new(user)
      end

      # users are listed below the line containing '-------------'
      if line =~/^----------------/
        user_block_started = true
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
        resources[name]['change_password'] = need_pw_change?(name, resources[name]['password'])
      end
    end
  end

  def self.need_pw_change?(username, password)
    Puppet.debug(username + " PW: " + password)
    begin
      scli_basic("--login", "--username", username, "--password", password) 
    rescue Puppet::ExecutionFailure => e
      return e.inspect =~ /Permission denied/
    end
    return false
  end

  
  def create 
    Puppet.debug("Creating ScaleIO user #{resource[:name]}")
    add_scaleio_user(resource[:name], resource[:role], resource[:password])
    @property_hash[:ensure] = :present
  end


  def change_password=(need_pw_change)
    Puppet.debug("Changing password for ScaleIO user #{resource[:name]}")
    change_scaleio_password(resource[:name], resource[:password])
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

