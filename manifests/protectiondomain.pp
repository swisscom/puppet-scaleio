# manage the callhome feature
class scaleio::protectiondomain(
  $name = $title
) {

  include ::scaleio::mdm

  # Only on Primary
  notify{"pdo module is executed":}
  scaleio_protectiondomain{$name:}
}
