# manage the callhome feature
class scaleio::mdm::callhome(
  $from_mail           = "callhome@${::fqdn}",
  $user                = 'callhome',
  $user_role           = 'Monitor',
  $password            = 'Callhome13',
  $mail_server_address = 'localhost',
  $customer_name       = $::domain,
  $to_mail             = 'root@localhost',
  $to_mail_emc          = '',
) {

  include ::scaleio::mdm
  ensure_packages(['mutt'])

  package::verifiable{'EMC-ScaleIO-callhome':
    version => $scaleio::version,
  }

  # Include primary mdm class, if this server shall be the primary (first setup)
  # or if we are running on the actual SIO primary mdm
  if (has_ip_address($::scaleio::mdm_ips[0]) and str2bool($::scaleio_mdm_clustersetup_needed)) or str2bool($::scaleio_is_primary_mdm) {
    # add callhome user
    scaleio_user{$user:
      role      => $user_role,
      password  => $password,
      require   => [Exec['scaleio::mdm::primary_add_secondary'], File[$scaleio::mdm::add_scaleio_user]],
      before    => File['/opt/emc/scaleio/callhome/cfg/conf.txt'];
    }
  }

  file{'/opt/emc/scaleio/callhome/cfg/conf.txt':
    content => template('scaleio/callhome_conf.erb'),
    owner   => root,
    group   => 0,
    mode    => '0644',
    require => Package::Verifiable['EMC-ScaleIO-callhome'];
  } ~> exec{'restart_callhome_service':
    command     => 'pkill -f \'scaleio/callhome\'',
    refreshonly => true,
  }
}
