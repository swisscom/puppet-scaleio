# manage the callhome feature
class scaleio::mdm::callhome {
  include ::scaleio
  ensure_packages('mutt')

  package{'EMC-ScaleIO-callhome':
    ensure => $scaleio::version,
  }

  $add_callhome_user = '/var/lib/puppet/module_data/scaleio/add_callhome_user.erb'

  file{$add_callhome_user:
    content => template('scaleio/add_callhome_user.erb'),
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

  exec{'scaleio::mdm::add_callhome_user':
    command => "${add_callhome_user}",
    unless  => "${scli_wrap} --query_user --username callhome",
  }
}
