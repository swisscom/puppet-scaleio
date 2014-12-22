# manage the callhome feature
class scaleio::mdm::callhome(
  $from_mail           = "callhome@${::fqdn}",
  $user                = 'callhome',
  $user_role           = 'Monitor',
  $password            = 'Callhome13',
  $mail_server_address = 'localhost',
  $customer_name       = $::domain,
  $to_mail             = 'root@localhost',
) {

  include ::scaleio::mdm
  ensure_packages(['mutt'])

  package{'EMC-ScaleIO-callhome':
    ensure => $scaleio::version,
  }

  # Include primary mdm class, if this server shall be the primary (first setup), but it has not yet been configured,
  # or if we are running on the actual SIO primary mdm
  if (has_ip_address($scaleio::primary_mdm_ip) and !str2bool($::scaleio_tb_connection_established)) or str2bool($::scaleio_is_primary_mdm) {
    $add_callhome_user = '/var/lib/puppet/module_data/scaleio/add_callhome_user.sh'

    file{$add_callhome_user:
      source  => 'puppet:///modules/scaleio/add_callhome_user.sh',
      owner   => root,
      group   => 0,
      mode    => '0700',
      require => [
        Package['EMC-ScaleIO-callhome'],
        Exec['scaleio::mdm::primary_go_into_cluster_mode'],
      ]
    }

    exec{'add_callhome_user.sh':
      command => "${add_callhome_user} ${user} ${user_role} ${password} ${::scaleio::password}",
      unless  => "${::scaleio::mdm::scli_wrap} --query_user --username callhome",
      before  => File['/opt/emc/scaleio/callhome/cfg/conf.txt'],
    }
  }

  file{'/opt/emc/scaleio/callhome/cfg/conf.txt':
    content => template('scaleio/callhome_conf.erb'),
    owner   => root,
    group   => 0,
    mode    => '0644',
    require => Package['EMC-ScaleIO-callhome'];
  } ~> exec{'restart_callhome_service':
    command     => 'pkill -f \'scaleio/callhome\'',
    refreshonly => true,
  }
}
