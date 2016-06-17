# manage a non-primary mdm
class scaleio::mdm::secondary {
  include ::scaleio

  # if $scaleio::use_consul{
  #   consul_kv{ "scaleio/${::scaleio::system_name}/cluster_setup/secondary":
  #     value   => 'ready',
  #     require => [Service['consul'], Package::Verifiable['EMC-ScaleIO-mdm']]
  #   }
  # }
}
