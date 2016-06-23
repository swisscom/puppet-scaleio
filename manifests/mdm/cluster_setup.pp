# setup a MDM cluster
class scaleio::mdm::cluster_setup {

  $primary_mdm_ips = join(any2array($::scaleio::mdms[$::scaleio::bootstrap_mdm_name]['ips']), ',')
  $primary_mdm_mgmt_ips = join(any2array($::scaleio::mdms[$::scaleio::bootstrap_mdm_name]['mgmt_ips']), ',')

  exec{ 'scaleio::mdm::cluster_setup::create_cluster':
    command => "scli --create_mdm_cluster --master_mdm_ip ${primary_mdm_ips} --master_mdm_management_ip ${primary_mdm_mgmt_ips} --master_mdm_name ${::scaleio::bootstrap_mdm_name} --use_nonsecure_communication --accept_license; sleep 5",
    onlyif  => 'scli --query_cluster --approve_certificate 2>&1 |grep -qE "Error: MDM failed command.  Status: The MDM cluster state is incorrect"',
    require => Exec['scaleio::mdm::installation::restart_mdm'],
  }->
  exec{ 'scaleio::mdm::cluster_setup::login_default':
    command => "scli --login --username admin --password ${::scaleio::old_password}",
    unless  => "scli --login --username admin --password ${::scaleio::password} && scli --logout",
  } ~>
  exec{ 'scaleio::mdm::cluster_setup::primary_change_pwd':
    command     => "scli --set_password --old_password ${::scaleio::old_password} --new_password ${scaleio::password}",
    refreshonly => true,
  }

  # wait until the MDM/TBs have been setup
  if $scaleio::use_consul{
    $mdm_tb_consul_keys = prefix(concat(
      scaleio_get_first_mdm_ips($::scaleio::mdms, 'ips'),
      scaleio_get_first_mdm_ips($::scaleio::tiebreakers, 'ips')
    ),
      "scaleio/${scaleio::system_name}/cluster_setup/")

    consul_kv_blocker{ $mdm_tb_consul_keys:
      tries     => 120,
      try_sleep => 30,
      require   => Consul_kv["scaleio/${::scaleio::system_name}/cluster_setup/${::scaleio::current_mdm_ip}"],
    } -> Scaleio_mdm<| |>
  }

  # create the MDMs as standby MDMs
  create_resources('scaleio_mdm', $scaleio::mdms, {
    ensure        => present,
    is_tiebreaker => false,
    require       => Exec['scaleio::mdm::cluster_setup::primary_change_pwd']
  })

  create_resources('scaleio_mdm', $scaleio::tiebreakers, {
    ensure        => present,
    is_tiebreaker => true,
    require       => Exec['scaleio::mdm::cluster_setup::primary_change_pwd']
  })

  Scaleio_mdm<||> -> Scaleio_mdm_cluster<||>

  scaleio_mdm_cluster{ 'mdm_cluster':
    mdm_names => keys($::scaleio::mdms),
    tb_names  => keys($::scaleio::tiebreakers),
  }
}