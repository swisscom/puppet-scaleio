# setup a primary mdm
class scaleio::mdm::primary {
  include scaleio::mdm

  # requires the license, password
  #validate_re($scaleio::license, '^[A-Z0-9]{38}$')
  validate_re($scaleio::password, '^[A-Za-z0-9_]+$')

  $scli_wrap         = $scaleio::mdm::scli_wrap

  if empty($scaleio::primary_mdm_ip) or empty($scaleio::secondary_mdm_ip) or empty($scaleio::tb_ip) {
    fail('For a primary mdm all three variables $scaleio::primary_mdm_ip, $scaleio::secondary_mdm_ip and $scaleio::tb_ip must be configured')
  }

  exec{'scaleio::mdm::primary_add_primary':
    command => "scli --add_primary_mdm --primary_mdm_ip ${scaleio::primary_mdm_ip} --accept_license && sleep 10",
    unless  => "scli --query_cluster | grep -qE '^ (Secondary|Primary) IP: ${scaleio::primary_mdm_ip}$'",
    require => Package['EMC-ScaleIO-mdm'],
    before  => Exec['scaleio::mdm::primary_add_secondary'],
  }

  # login and pwd set dance
  if $scaleio::password != 'admin' {
    exec{'scaleio::mdm::primary_login_default':
      command => "scli --login --username admin --password ${scaleio::old_password}",
      unless  => "scli --login --username admin --password ${scaleio::password} && scli --logout",
      require => Exec['scaleio::mdm::primary_add_primary'],
    } ~> exec{'scaleio::mdm::primary_change_pwd':
      command     => "scli --set_password --old_password ${scaleio::old_password} --new_password ${scaleio::password}",
      refreshonly => true,
      before      => Exec['scaleio::mdm::primary_add_secondary'],
    }
  }

  exec{'scaleio::mdm::primary_add_secondary':
    command => "${scli_wrap} --add_secondary_mdm --secondary_mdm_ip ${scaleio::secondary_mdm_ip}",
    unless  => "scli --query_cluster | grep -qE '^ (Secondary|Primary) IP: ${scaleio::secondary_mdm_ip}$'",
  } -> exec{'scaleio::mdm::primary_add_tb':
    command => "${scli_wrap} --add_tb --tb_ip ${scaleio::tb_ip}",
    unless  => "scli --query_cluster | grep -qE '^ Tie-Breaker IP: ${scaleio::tb_ip}$'",
  } -> exec{'scaleio::mdm::primary_go_into_cluster_mode':
    command => "${scli_wrap} --switch_to_cluster_mode",
    unless  => 'scli --query_cluster | grep -qE \'^ Mode: Cluster, Cluster State: \'',
  }

  if $scaleio::system_name {
    validate_re($scaleio::system_name, '^[a-z0-9-]+$')
    exec{'scaleio::mdm::primary_rename_system':
      command => "${scli_wrap} --rename_system --new_name ${scaleio::system_name}",
      unless  => "scli --query_cluster | grep -qE '^ Name: ${scaleio::system_name}$'",
      require => Exec['scaleio::mdm::primary_go_into_cluster_mode'],
    }
  }

#  if $scaleio::syslog_ip_port {
#    validate_re($scaleio::syslog_ip_port, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}:[0-9]+$')
#    $splitted_ip_port = split($scaleio::syslog_ip_port,':')
#    exec{'scaleio::mdm::primary_configure_syslog':
#      command => "scli --start_remote_syslog --remote_syslog_server_ip ${splitted_ip_port[0]} --remote_syslog_server_port ${splitted_ip_port[1]} --syslog_facility 16",
#      unless  => "TODO: check if configured right",
#      require => Exec['scaleio::mdm::primary_go_into_cluster_mode'],
#    }
#  }

  # TODO: default pool is created for a new protection domain, but deleted in the next puppet run
  # TODO: last pool cannot be deleted - results in error
  create_resources('scaleio_protection_domain', $scaleio::protection_domains, {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scli_wrap]]})
  create_resources('scaleio_storage_pool',      $scaleio::storage_pools,      {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scli_wrap]]})
  create_resources('scaleio_sds',               $scaleio::sds,                {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scli_wrap]]})
  create_resources('scaleio_sdc_name',          $scaleio::sdc_names,          {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scli_wrap]], tag => 'scaleio_tag_sdc_name'})
  create_resources('scaleio_volume',            $scaleio::volumes,            {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scli_wrap]], tag => 'scaleio_tag_volume'})

  # Make sure that the sdc are renamed before trying to map the volumes to those names
  # This cannot be done with autorequire in the provider as the unique name of the resource 'scaleio_sdc_name' must be the IP and not the name
  Scaleio_sdc_name<| tag == 'scaleio_tag_sdc_name' |> -> Scaleio_volume<| tag == 'scaleio_tag_volume' |>

  resources {
    'scaleio_protection_domain':
      purge => $scaleio::purge;
    'scaleio_storage_pool':
      purge => $scaleio::purge;
    'scaleio_sds':
      purge => $scaleio::purge;
    'scaleio_sdc_name':
      purge => $scaleio::purge;
    'scaleio_volume':
      purge => $scaleio::purge;
  }
}
