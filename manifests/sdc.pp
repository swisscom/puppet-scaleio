# manage a sdc
class scaleio::sdc {
  include ::scaleio

  # only do a new installation of the package
  package_verifiable{'EMC-ScaleIO-sdc':
    version        => $scaleio::version,
    manage_package => !$package_emc_scaleio_sdc_version,
    tag            => 'scaleio-install',
    require        => Package['numactl'],
  }

  if $::scaleio::mdms {
    $mdm_ips_joined = join(scaleio_get_all_mdm_ips($::scaleio::mdms, 'ips'), ',')

    service{'scini':
      ensure  => running,
      enable  => true,
      require => Package_verifiable['EMC-ScaleIO-sdc'],
      before  => Exec['scaleio::sdc_add_mdm'],
    }

    # add a new MDM, if no one is defined
    exec{'scaleio::sdc_add_mdm':
      command => "/bin/emc/scaleio/drv_cfg --add_mdm --ip ${mdm_ips_joined} --file /bin/emc/scaleio/drv_cfg.txt",
      unless  => "grep -qE '^mdm ' /bin/emc/scaleio/drv_cfg.txt",
    }->

    # replace the old MDM definition
    exec{'scaleio::sdc_mod_mdm':
      command => "/bin/emc/scaleio/drv_cfg --mod_mdm_ip --ip $(grep -E '^mdm' /bin/emc/scaleio/drv_cfg.txt |awk '{print \$2}' |awk -F ',' '{print \$1}') --new_mdm_ip ${mdm_ips_joined} --file /bin/emc/scaleio/drv_cfg.txt",
      unless  => "grep -qE '^mdm ${mdm_ips_joined}$' /bin/emc/scaleio/drv_cfg.txt",
    }
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
