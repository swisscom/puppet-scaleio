# manage the callhome feature
class scaleio::protectiondomain(
  $name = $title
) {

  include ::scaleio::mdm

  # Only on Primary
  if has_ip_address($scaleio::primary_mdm_ip) {
    scaleio_protectiondomain($name)
  }

}
