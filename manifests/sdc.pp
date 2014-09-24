# manage a sdc
class scaleio::sdc {
  include ::scaleio
  package{'EMC-ScaleIO-sdc':
    ensure => $scaleio::version,
  }

  if empty($scaleio::primary_mdm_ip) or empty($scaleio::secondary_mdm_ip) {
    fail('Both $scaleio::primary_mdm_ip and $scaleio::secondary_mdm_ip must be set to configure an sdc')
  }

  exec{'scaleio::sdc_add_mdm':
    command => "/bin/emc/scaleio/drv_cfg --add_mdm --ip ${scaleio::primary_mdm_ip},${scaleio::secondary_mdm_ip} --file /bin/emc/scaleio/drv_cfg.txt",
    unless  => "grep -qE '^mdm ${scaleio::primary_mdm_ip},${scaleio::secondary_mdm_ip}$' /bin/emc/scaleio/drv_cfg.txt",
    require => Package['EMC-ScaleIO-sdc'],
  }
}
