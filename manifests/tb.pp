# manage a tb
class scaleio::tb {
  include ::scaleio
  package{'EMC-ScaleIO-tb':
    ensure => $scaleio::version,
  }
}
