# manage the callhome feature
class scaleio::mdm::callhome {
  include ::scaleio
  ensure_packages('mutt')

  package{'EMC-ScaleIO-callhome':
    ensure => $scaleio::version,
  }
  # TODO: how to configure
}
