# setup a primary mdm
class scaleio::mdm::primary {
  include scaleio::mdm

  # requires the license, password
  #validate_re($scaleio::license, '^[A-Z0-9]{38}$')
  validate_re($scaleio::password, '^[A-Za-z0-9_]+$')

  $scli_wrap         = $scaleio::mdm::scli_wrap

  if size($::scaleio::mdm_ips) < 2 or size($::scaleio::tb_ips) < 1 {
    fail('For a primary mdm at least two MDMs and one tiebreaker must be configured')
  }

  exec{'scaleio::mdm::primary_add_primary':
    command => "scli --add_primary_mdm --primary_mdm_ip ${::scaleio::mdm_ips[0]} --accept_license && sleep 10",
    unless  => "scli --query_cluster | grep -qE '^ Primary (MDM )?IP: (([0-9]+.?))+$'",
    require => Package::Verifiable['EMC-ScaleIO-mdm'],
    before  => Exec['scaleio::mdm::primary_add_secondary'],
  }

  if $scaleio::use_consul {
    ensure_resource('consul_kv_blocker',
      "scaleio/${::scaleio::system_name}/cluster_setup/secondary",
      {tries => 120, try_sleep => 30, require => Service['consul']}
    )
    Consul_kv_blocker["scaleio/${::scaleio::system_name}/cluster_setup/secondary"] ->
      Exec['scaleio::mdm::primary_add_primary']

    ensure_resource('consul_kv_blocker',
      "scaleio/${::scaleio::system_name}/cluster_setup/tiebreaker",
      {tries => 120, try_sleep => 30, require => Service['consul']}
    )
    Consul_kv_blocker["scaleio/${::scaleio::system_name}/cluster_setup/tiebreaker"] ->
      Exec['scaleio::mdm::primary_add_tb']
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

  # Setup SIO cluster
  exec{'scaleio::mdm::primary_add_secondary':
    command => "${scli_wrap} --add_secondary_mdm --secondary_mdm_ip ${::scaleio::mdm_ips[1]}",
    unless  => "scli --query_cluster | grep -qE '^ Secondary (MDM )?IP: (([0-9]+.?))+$'",
    require => [File[$scli_wrap], Package::Verifiable['EMC-ScaleIO-mdm']],
  } ->
  exec{'scaleio::mdm::primary_add_tb':
    command => "${scli_wrap} --add_tb --tb_ip ${::scaleio::tb_ips[0]}",
    unless  => "scli --query_cluster | grep -qE '^ Tie-Breaker IP: (([0-9]+.?))+$'",
  } ->
  exec{'scaleio::mdm::primary_go_into_cluster_mode':
    command => "${scli_wrap} --switch_to_cluster_mode",
    unless  => 'scli --query_cluster | grep -qE \'^ Mode: Cluster, Cluster State: \'',
  }

  # Set SIO system name
  if $scaleio::system_name {
    validate_re($scaleio::system_name, '^[a-z0-9-]+$')
    exec{'scaleio::mdm::primary_rename_system':
      command => "${scli_wrap} --rename_system --new_name ${scaleio::system_name}",
      unless  => "scli --query_cluster | grep -qE '^ Name: ${scaleio::system_name}$'",
      require => Exec['scaleio::mdm::primary_go_into_cluster_mode'],
    }
  }

  # Setup Syslog
  if $scaleio::syslog_ip_port {
    validate_re($scaleio::syslog_ip_port, '^[\w\-\.]+:[0-9]+$')
    $splitted_ip_port = split($scaleio::syslog_ip_port,':')

    if $scaleio::version =~ /^1.30-/ {
      exec{'scaleio::mdm::primary_configure_syslog':
        command => "${scli_wrap} --start_remote_syslog --remote_syslog_server_ip ${splitted_ip_port[0]} --remote_syslog_server_port ${splitted_ip_port[1]}",
        unless  => "netstat -apn |grep mdm |egrep -q ':${splitted_ip_port[1]}'",
        require => Exec['scaleio::mdm::primary_add_secondary'],
      }
    }
    else {
      scaleio_syslog{$splitted_ip_port[0]:
        port    => $splitted_ip_port[1],
        require => Exec['scaleio::mdm::primary_add_secondary']
      }
    }
  }

  # Manage SDC access restriction
  if $scaleio::version !~ /^1.30-/ and $::scaleio::restricted_sdc_mode {
    $real_restricted_sdc_mode = 'enabled'
    $cur_restricted_sdc_mode = 'disabled'
  } else {
    $real_restricted_sdc_mode = 'disabled'
    $cur_restricted_sdc_mode = 'enabled'
  }
  exec{'scaleio::mdm::manage_sdc_access_restriction':
    command => "${scli_wrap} --set_restricted_sdc_mode --restricted_sdc_mode ${real_restricted_sdc_mode}",
    onlyif  => "${scli_wrap} --query_all |grep -q 'MDM restricted SDC mode: ${cur_restricted_sdc_mode}'",
  }

  if size($scaleio::mgmt_addresses) > 0 {
    $mgmt_addresses = join($::scaleio::mgmt_addresses, ',')
  } else {
    $mgmt_addresses = join($::scaleio::mdm_ips, ',')
  }

  exec{'scaleio::mdm::set_mgmt_addresses':
    command => "${scli_wrap} --modify_management_ip --mdm_management_ip ${mgmt_addresses}",
    unless  => "scli --query_cluster |sed 's/\s*//g' | grep -qE '^ManagementIP:${mgmt_addresses}$'",
    require => Exec['scaleio::mdm::primary_go_into_cluster_mode'],
  }

  if $scaleio::monitoring_user {
    scaleio_user{$scaleio::monitoring_user:
      role     => 'Monitor',
      password => $scaleio::monitoring_passwd,
      require  => [Exec['scaleio::mdm::primary_add_secondary'], File[$scaleio::mdm::add_scaleio_user]],
    }
  }

  # TODO: default pool is created for a new protection domain, but deleted in the next puppet run
  # TODO: last pool cannot be deleted - results in error
  create_resources('scaleio_user',              $scaleio::users,              {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scaleio::mdm::add_scaleio_user]]})
  create_resources('scaleio_protection_domain', $scaleio::protection_domains, {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary']})
  create_resources('scaleio_storage_pool',      $scaleio::storage_pools,      {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary']})
  create_resources('scaleio_sds',               $scaleio::sds,                {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary'], tag => 'scaleio_tag_sds', useconsul => $scaleio::use_consul, ramcache_size => $scaleio::ramcache_size + 0})
  create_resources('scaleio_sdc_name',          $scaleio::sdc_names,          {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], Exec['scaleio::mdm::manage_sdc_access_restriction']], tag => 'scaleio_tag_sdc_name', restricted_sdc_mode => $real_restricted_sdc_mode})
  create_resources('scaleio_volume',            $scaleio::volumes,            {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary'], tag => 'scaleio_tag_volume'})

  # Make sure that the sdc are renamed before trying to map the volumes to those names
  # This cannot be done with autorequire in the provider as the unique name of the resource 'scaleio_sdc_name' must be the IP and not the name
  Scaleio_sds<| tag == 'scaleio_tag_sds' |> -> Scaleio_sdc_name<| tag == 'scaleio_tag_sdc_name' |>
  Scaleio_sdc_name<| tag == 'scaleio_tag_sdc_name' |> -> Scaleio_volume<| tag == 'scaleio_tag_volume' |>

  # Set value when all volumes have been created
  if $scaleio::use_consul {
    consul_kv{"scaleio/${::scaleio::system_name}/cluster_setup/primary":
      value   => 'ready',
    }
    Scaleio_volume<| tag == 'scaleio_tag_volume' |> ->
      Consul_kv["scaleio/${::scaleio::system_name}/cluster_setup/primary"]
  }

  #resources {
  #  'scaleio_protection_domain':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_storage_pool':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_sds':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_sdc_name':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_volume':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #}
}
