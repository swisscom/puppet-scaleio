# bootstrap a MDM cluster
class scaleio::mdm::bootstrap {
  file_line { 'scaleio::mdm::bootstrap::actor':
    path => '/opt/emc/scaleio/mdm/cfg/conf.txt',
    line => 'actor_role_is_manager=1',
  } ~>
  exec{ 'scaleio::mdm::bootstrap::restart_mdm':
    command     => 'systemctl restart mdm.service',
    refreshonly => true,
  } ->
  exec{ 'scaleio::mdm::bootstrap::create_cluster':
    command => "scli --create_mdm_cluster --master_mdm_ip ${::scaleio::mdm_ips[0]} --use_nonsecure_communication --accept_license",
    onlyif  => 'scli --query_cluster --approve_certificate\ grep -qE "Error: MDM failed command.  Status: The MDM cluster state is incorrect"',
  }
}