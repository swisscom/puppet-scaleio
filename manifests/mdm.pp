# manage a mdm
class scaleio::mdm {
  $scli_wrap         = '/var/lib/puppet/module_data/scaleio/scli_wrap'
  $add_scaleio_user  = '/var/lib/puppet/module_data/scaleio/add_scaleio_user'

  include ::scaleio

  if $scaleio::use_consul {
    include ::consul
  }

  package::verifiable{'EMC-ScaleIO-mdm':
    version => $scaleio::version
  }

  file{
    $scli_wrap:
      content => template('scaleio/scli_wrap.erb'),
      owner   => root,
      group   => 0,
      mode    => '0700',
      require => Package::Verifiable['EMC-ScaleIO-mdm'];
  }

  if $scaleio::external_monitoring_user {
    file{
      '/var/lib/puppet/module_data/scaleio/scli_wrap_monitoring':
        content => template('scaleio/scli_wrap_monitoring.erb'),
        owner   => root,
        group   => 0,
        mode    => '0700',
        require => Package::Verifiable['EMC-ScaleIO-mdm'];
    }
  }

  file{
    $add_scaleio_user:
      content => template('scaleio/add_scaleio_user.erb'),
      owner   => root,
      group   => 0,
      mode    => '0700',
      require => Package::Verifiable['EMC-ScaleIO-mdm'];
  }

  # Include primary mdm class, if this server shall be the primary (first setup)
  # or if we are running on the actual SIO primary mdm

  if (has_ip_address($::scaleio::mdm_ips[0]) and str2bool($::scaleio_mdm_clustersetup_needed)) or str2bool($::scaleio_is_primary_mdm) {
    include scaleio::mdm::primary
  }elsif ($scaleio::use_consul and has_ip_address($::scaleio::mdm_ips[1])) {
      consul_kv{"scaleio/${::scaleio::system_name}/cluster_setup/secondary":
        value   => 'ready',
        require => Package::Verifiable['EMC-ScaleIO-mdm']
      }
  }

  # If there are more than two MDMs defined, then we have to setup
  # standy MDMs using the MDM failover script
  if size($::scaleio::mdm_ips) > 2 or size($::scaleio::tb_ips) > 1 {

    # prepare input for mdm_failover_post_install
    $failover_mdms_joined = join($::scaleio::mdm_ips, ']+[')
    $failover_mdms = "[${failover_mdms_joined}]"
    $failover_tbs_joined = join($::scaleio::tb_ips, ']+[')
    $failover_tbs = "[${failover_tbs_joined}]"

    exec{'scaleio::mdm::setup_failover':
      command => "/opt/emc/scaleio/mdm_failover/bin/delete_service.sh ; ps -ef |grep '[m]dm_failover.py' |awk '{print \$2}' |xargs -r kill ; /opt/emc/scaleio/mdm_failover/bin/mdm_failover_post_install.py --mdms_list='${failover_mdms}' --tbs_list='${failover_tbs}' --username=admin --password='${::scaleio::password}'",
      unless  => "fgrep \"mdms': '${failover_mdms}'\" /opt/emc/scaleio/mdm_failover/cfg/conf.txt |fgrep \"tbs': '${failover_tbs}'\" |fgrep $(echo '${::scaleio::password}' |base64 |awk '{ \$1 = substr(\$1, 1, 25) } 1')",
      require => Package::Verifiable['EMC-ScaleIO-mdm'],
      returns => [ 0, '', ' ']
    }
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
