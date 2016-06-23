# install the MDM package either for an MDM or a TB
# and set the corresponding role
class scaleio::mdm::installation(
  $is_tiebreaker = true,
){

  ensure_packages(['python'])

  # only do a new installation of the package
  package::verifiable{ 'EMC-ScaleIO-mdm':
    version        => $scaleio::version,
    manage_package => !$::package_emc_scaleio_mdm_version,
    tag            => 'scaleio-install',
    require        => [Package['python'], Package['numactl']],
  }

  $actor_role_is_manager = $is_tiebreaker ? {
    true  => '0',
    false => '1',
  }


  # set the actor role to manager
  file_line { 'scaleio::mdm::installation::actor':
    path    => '/opt/emc/scaleio/mdm/cfg/conf.txt',
    line    => "actor_role_is_manager=${actor_role_is_manager}",
    match   => '^actor_role_is_manager=',
    require => Package::Verifiable['EMC-ScaleIO-mdm'],
  } ~>
  exec{ 'scaleio::mdm::installation::restart_mdm':
    # give the mdm time to switch its role
    command     => 'systemctl restart mdm.service; sleep 15',
    refreshonly => true,
  }

  if $scaleio::use_consul {
    include ::consul

    $mdm_tb_ip = $is_tiebreaker ?{
      true  => $::scaleio::current_tb_ip,
      false => $::scaleio::current_mdm_ip,
    }

    consul_kv{ "scaleio/${::scaleio::system_name}/cluster_setup/${mdm_tb_ip}":
      value   => 'ready',
      require => Exec['scaleio::mdm::installation::restart_mdm'],
    }
  }
}