# manage a tb
class scaleio::tb {
  include ::scaleio
  if $scaleio::use_consul {
    require ::consul
  }

  # only do a new installation of the package
  if $package_emc_scaleio_tb_version {
    package{'EMC-ScaleIO-tb':
      ensure => 'installed',
    }
  }

  package::verifiable{'EMC-ScaleIO-tb':
    version        => $scaleio::version,
    manage_package => !$package_emc_scaleio_tb_version,
    tag            => 'scaleio-install',
  }

  if $scaleio::use_consul and has_ip_address($::scaleio::tb_ips[0]) {
    consul_kv{"scaleio/${::scaleio::system_name}/cluster_setup/tiebreaker":
      value   => 'ready',
      require => [Service['consul'], Package::Verifiable['EMC-ScaleIO-tb']]
    }
  }
}
