# manage a sdc
class scaleio::sdc {
  include ::scaleio
  package::verifiable{'EMC-ScaleIO-sdc':
    version => $scaleio::version,
  }

  if size($::scaleio::mdm_ips) < 2{
    fail('At least two MDM IPs must be set to configure an sdc')
  }

  $mdm_ips_joined = join($::scaleio::mdm_ips, ',')

  # add a new MDM, if no one is defined
  exec{'scaleio::sdc_add_mdm':
    command => "/bin/emc/scaleio/drv_cfg --add_mdm --ip ${mdm_ips_joined} --file /bin/emc/scaleio/drv_cfg.txt",
    unless  => "grep -qE '^mdm ' /bin/emc/scaleio/drv_cfg.txt",
    require => 'Package::Verifiable[EMC-ScaleIO-sdc]',
  }->

  # replace the old MDM definition
  exec{'scaleio::sdc_mod_mdm':
    command => "/bin/emc/scaleio/drv_cfg --mod_mdm_ip --ip $(grep -E '^mdm' /bin/emc/scaleio/drv_cfg.txt |awk '{print \$2}' |awk -F ',' '{print \$1}') --new_mdm_ip ${mdm_ips_joined} --file /bin/emc/scaleio/drv_cfg.txt",
    unless  => "grep -qE '^mdm ${mdm_ips_joined}$' /bin/emc/scaleio/drv_cfg.txt",
    require => 'Package::Verifiable[EMC-ScaleIO-sdc]',
  }

  if $::scaleio::lvm {
    file_line { 'scaleio_lvm_types':
      ensure => present,
      path   => '/etc/lvm/lvm.conf',
      line   => '    types = [ "scini", 16 ]',
      match  => 'types\s*=\s*\[',
    }
  }

}
