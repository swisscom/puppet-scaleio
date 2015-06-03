# manage a tb
class scaleio::tb {
  include ::scaleio
  require ::consul
  package{'EMC-ScaleIO-tb':
    ensure => $scaleio::version,
  }

  if $scaleio::use_consul {
    consul_kv{'scaleio/cluster_setup/tiebreaker':
      value   => 'ready',
      require => Package['EMC-ScaleIO-tb']
    }
  }
}
