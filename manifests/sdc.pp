# manage a sdc
class scaleio::sdc {
  include ::scaleio
  package{'EMC-ScaleIO-sdc':
    ensure => $scaleio::version,
  }

  if size($scaleio::real_mdm_ips) < 2{
    fail('At least two MDM IPs must be set to configure an sdc')
  }

  $mdm_ips_joined = join($scaleio::real_mdm_ips, ',')

  exec{'scaleio::sdc_add_mdm':
    command => "/bin/emc/scaleio/drv_cfg --add_mdm --ip ${mdm_ips_joined} --file /bin/emc/scaleio/drv_cfg.txt",
    unless  => "grep -qE '^mdm ${mdm_ips_joined}$' /bin/emc/scaleio/drv_cfg.txt",
    require => Package['EMC-ScaleIO-sdc'],
  }
}
