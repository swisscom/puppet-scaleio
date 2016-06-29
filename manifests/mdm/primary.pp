# setup a primary mdm
class scaleio::mdm::primary {
  $scli_wrap = $scaleio::mdm::scli_wrap

  include scaleio::mdm::cluster_setup
  include scaleio::mdm::resources

  # First do the cluster setup, then create the SIO resources
  Class['scaleio::mdm::cluster_setup'] -> Class['scaleio::mdm::resources']


  # Set SIO system name
  if $scaleio::system_name {
    validate_re($scaleio::system_name, '^[a-z0-9-]+$', 'ScaleIO system name must be alphanumeric')
    exec{ 'scaleio::mdm::primary::rename_system':
      command => "${scli_wrap} --rename_system --new_name ${scaleio::system_name}",
      unless  => "${scli_wrap} --query_cluster | grep -qE '^ Name: ${scaleio::system_name}\\s*Mode'",
      require => Class['scaleio::mdm::cluster_setup'],
    }
  }

  # manage SDC restriction mode
  if $::scaleio::restricted_sdc_mode{
    $restricted_sdc_mode_text = 'enabled'
  } else{
    $restricted_sdc_mode_text = 'disabled'
  }

  exec{ 'scaleio::mdm::primary::manage_sdc_access_restriction':
    command => "${scli_wrap} --set_restricted_sdc_mode --restricted_sdc_mode ${restricted_sdc_mode_text}",
    unless  => "${scli_wrap} --query_all |grep -q 'MDM restricted SDC mode: ${restricted_sdc_mode_text}'",
    require => Class['scaleio::mdm::cluster_setup'],
    before  => Class['scaleio::mdm::resources'],
  }

  # Create a monitoring user
  if $scaleio::monitoring_user {
    scaleio_user{$scaleio::monitoring_user:
      role     => 'Monitor',
      password => $scaleio::monitoring_passwd,
      require  => Class['scaleio::mdm::cluster_setup'],
    }
  }


  #
  # # Setup Syslog
  # if $scaleio::syslog_ip_port {
  #   validate_re($scaleio::syslog_ip_port, '^[\w\-\.]+:[0-9]+$')
  #   $splitted_ip_port = split($scaleio::syslog_ip_port,':')
  #
  #   if $scaleio::version =~ /^1.30-/ {
  #     exec{'scaleio::mdm::primary_configure_syslog':
  #       command => "${scli_wrap} --start_remote_syslog --remote_syslog_server_ip ${splitted_ip_port[0]} --remote_syslog_server_port ${splitted_ip_port[1]}",
  #       unless  => "netstat -apn |grep mdm |egrep -q ':${splitted_ip_port[1]}'",
  #       require => Exec['scaleio::mdm::primary_add_secondary'],
  #     }
  #   }
  #   else {
  #     scaleio_syslog{$splitted_ip_port[0]:
  #       port    => $splitted_ip_port[1],
  #       require => Exec['scaleio::mdm::primary_add_secondary']
  #     }
  #   }
  # }

}
