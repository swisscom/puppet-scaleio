# manage a mdm
class scaleio::mdm {
  $scli_wrap         = '/var/lib/puppet/module_data/scaleio/scli_wrap'

  include ::scaleio
  package{'EMC-ScaleIO-mdm':
    ensure => $scaleio::version,
  }

  file{
    $scli_wrap:
      content => template('scaleio/scli_wrap.erb'),
      owner   => root,
      group   => 0,
      mode    => '0700',
      require => Package['EMC-ScaleIO-mdm'];
  }

  # Include primary mdm class, if this server shall be the primary, but it has not yet been configured. 
  # Or if we are running on the actual SIO primary mdm
  if (has_ip_address($scaleio::primary_mdm_ip) and !str2bool($::scaleio_tb_connection_established)) or str2bool($::scaleio_is_primary_mdm) {
    include scaleio::mdm::primary
  }

  if $scaleio::callhome {
    include scaleio::mdm::callhome
  }

  file{'/var/lib/puppet/module_data/scaleio':
    ensure => directory,
    owner  => root,
    group  => 0,
    mode   => '0600',
  }
}
