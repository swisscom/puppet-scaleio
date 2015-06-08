# manage a sds
class scaleio::sds {
  include ::scaleio
  package::verifiable{'EMC-ScaleIO-sds':
    version => $scaleio::version,
  }
}
