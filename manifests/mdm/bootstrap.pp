# bootstrap a MDM cluster
class scaleio::mdm::bootstrap {
  exec{ 'scaleio::mdm::bootstrap::create_cluster':
    command => "scli --create_mdm_cluster --master_mdm_ip ${::scaleio::mdm_ips[0]} --use_nonsecure_communication --accept_license; sleep 5",
    onlyif  => 'scli --query_cluster --approve_certificate 2>&1 |grep -qE "Error: MDM failed command.  Status: The MDM cluster state is incorrect"',
    require => Exec['scaleio::mdm::installation::restart_mdm'],
  }->
  exec{ 'scaleio::mdm::bootstrap::login_default':
    command => "scli --login --username admin --password ${scaleio::old_password}",
    unless  => "scli --login --username admin --password ${scaleio::password} && scli --logout",
  } ~> exec{ 'scaleio::mdm::bootstrap::primary_change_pwd':
    command     => "scli --set_password --old_password ${scaleio::old_password} --new_password ${scaleio::password}",
    refreshonly => true,
  }
}