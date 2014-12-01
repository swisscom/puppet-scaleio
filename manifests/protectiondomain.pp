# manage the callhome feature
class scaleio::protectiondomain(
  $name = $title
) {

  include ::scaleio::mdm

  # Only on Primary
  notify{"pdo module is executed":}
  if has_ip_address($scaleio::primary_mdm_ip) {
    notify{"pdo module is executed on primary":}
    scaleio_protectiondomain{$name:}
  }

}
