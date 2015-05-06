# manage a tb
class scaleio::tb {
  include ::scaleio
  require ::consul
  package{'EMC-ScaleIO-tb':
    ensure => $scaleio::version,
  }
  consul_kv{'scaleio/cluster_setup_tiebreaker':
    value   => 'ready',
    require => Package['EMC-ScaleIO-tb']
  }
}
