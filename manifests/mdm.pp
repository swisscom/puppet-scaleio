# manage a mdm
class scaleio::mdm {
  $scli_wrap         = '/var/lib/puppet/module_data/scaleio/scli_wrap'
  $add_scaleio_user  = '/var/lib/puppet/module_data/scaleio/add_scaleio_user'

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

  file{
    $add_scaleio_user:
      content => template('scaleio/add_scaleio_user.erb'),
      owner   => root,
      group   => 0,
      mode    => '0700',
      require => Package['EMC-ScaleIO-mdm'];
  }

  # Include primary mdm class, if this server shall be the primary (first setup), but it has not yet been configured (checked if there is no open connection to the tie-breaker),
  # or if we are running on the actual SIO primary mdm
  if (has_ip_address($scaleio::real_mdm_ips[0]) and str2bool($::scaleio_mdm_clustersetup_needed)) or str2bool($::scaleio_is_primary_mdm) {
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
