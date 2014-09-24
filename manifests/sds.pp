# manage a sds
class scaleio::sds {
  include ::scaleio
  package{'EMC-ScaleIO-sds':
    ensure => $scaleio::version,
  }
}
