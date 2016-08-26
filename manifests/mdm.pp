# manage a mdm
class scaleio::mdm {
  $script_dir              = '/opt/emc/scaleio/scripts'
  $scli_wrap               = "${script_dir}/scli_wrap.sh"
  $add_scaleio_user        = "${script_dir}/add_scaleio_user.sh"
  $change_scaleio_password = "${script_dir}/change_scaleio_password.sh"

  include scaleio::mdm::monitoring

  class{'scaleio::mdm::installation':
    is_tiebreaker => false,
  }

  file{
    $script_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      require => Package_verifiable['EMC-ScaleIO-mdm'];
    $scli_wrap:
      content => template('scaleio/scli_wrap.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      require => File[$script_dir];
    $add_scaleio_user:
      content => template('scaleio/add_scaleio_user.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      require => File[$scli_wrap];
    $change_scaleio_password:
      content => template('scaleio/change_scaleio_password.sh.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0700',
      require => File[$add_scaleio_user];
    '/etc/bash_completion.d/si':
      content => 'complete -o bashdefault -o default -o nospace -F _scli si',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File[$script_dir];
    '/usr/bin/si':
      ensure => 'link',
      target => $scli_wrap;
  }

  # Include primary mdm class, if this server shall be the primary (first setup)
  # or if we are running on the actual SIO primary mdm
  if (has_ip_address($scaleio::cluster_setup_ip) and str2bool($scaleio_mdm_clustersetup_needed)) or str2bool($scaleio_is_primary_mdm) {
    include scaleio::mdm::primary
    File[$change_scaleio_password] -> Class['scaleio::mdm::primary']
  }

}
