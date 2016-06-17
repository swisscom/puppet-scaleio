# manage a tb
class scaleio::tb {

  class{'scaleio::mdm::installation':
    is_tiebreaker => true,
  }

  if $scaleio::use_consul {
    require ::consul
  }

  if $scaleio::use_consul and has_ip_address($::scaleio::tb_ips[0]) {
    consul_kv{"scaleio/${::scaleio::system_name}/cluster_setup/tiebreaker":
      value   => 'ready',
      require => [Service['consul'], Package::Verifiable['EMC-ScaleIO-mdm']]
    }
  }
}
