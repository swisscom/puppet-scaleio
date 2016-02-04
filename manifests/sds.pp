# manage a sds
class scaleio::sds {
  include ::scaleio

  # only do a new installation of the package
  if $package_emc_scaleio_sds_version {
    package{'EMC-ScaleIO-sds':
      ensure => 'installed',
    }
  }

  package::verifiable{'EMC-ScaleIO-sds':
    version        => $scaleio::version,
    manage_package => !$package_emc_scaleio_sds_version,
  }
}
