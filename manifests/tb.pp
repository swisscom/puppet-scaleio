# manage a tb
class scaleio::tb {
  include ::scaleio
  if $scaleio::use_consul {
    require ::consul
  }
  package::verifiable{'EMC-ScaleIO-tb':
    version => $scaleio::version,
  }

  if $scaleio::use_consul and has_ip_address($scaleio::real_tb_ips[0]) {
    consul_kv{'scaleio/cluster_setup/tiebreaker':
      value   => 'ready',
      require => Package::Verifiable['EMC-ScaleIO-tb']
    }
  }
}
