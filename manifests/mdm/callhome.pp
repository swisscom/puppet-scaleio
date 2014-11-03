# manage the callhome feature
class scaleio::mdm::callhome(
  $from_mail           = "callhome@${::fqdn}",
  $user                = 'callhome',
  $user_role           = 'Monitor',
  $mail_server_address = 'localhost',
  $customer_name       = $::domain,
  $to_mail             = 'root@localhost',
) {

  include ::scaleio
  include ::scaleio::mdm
  ensure_packages('mutt')

  package{'EMC-ScaleIO-callhome':
    ensure => $scaleio::version,
  }

  $add_callhome_user = '/var/lib/puppet/module_data/scaleio/add_callhome_user.sh'

  file{$add_callhome_user:
    source  => 'puppet:///modules/scaleio/add_callhome_user.sh',
    owner   => root,
    group   => 0,
    mode    => '0700',
    require => Package['EMC-ScaleIO-callhome'];
  }
  
  file{'/opt/emc/scaleio/callhome/cfg/conf.txt':
    ensure => file,
    content => template('scaleio/callhome_conf.erb'),
    owner   => root,
    group   => 0,
    mode    => '0644',
    require => Package['EMC-ScaleIO-callhome'];
  }

  exec{'add_callhome_user.sh':
    command => "${add_callhome_user} ${user} ${user_role} ${::scaleio::callhome_password} ${::scaleio::password}",
    unless  => "${::scaleio::mdm::scli_wrap} --query_user --username callhome",
  }
}
