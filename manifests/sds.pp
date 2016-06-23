# manage a sds
class scaleio::sds {
  include ::scaleio

  # only do a new installation of the package
  package::verifiable{'EMC-ScaleIO-sds':
    version        => $scaleio::version,
    manage_package => !$::package_emc_scaleio_sds_version,
    tag            => 'scaleio-install',
    require        => Package['numactl'],
  }
}
