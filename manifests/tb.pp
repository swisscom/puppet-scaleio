# manage a tb
class scaleio::tb {
  include ::scaleio
  require ::consul
  package::verifiable{'EMC-ScaleIO-tb':
    version => $scaleio::version,
  }

  if $scaleio::use_consul {
    consul_kv{'scaleio/cluster_setup/tiebreaker':
      value   => 'ready',
      require => Package::Verifiable['EMC-ScaleIO-tb']
    }
  }
}
