# manage the protectiondomain
class scaleio::protectiondomain(
  $name = undef
) {

  include ::scaleio::mdm

  # Only on Primary
  notify{"pdo module is executed":}
  scaleio_protectiondomain{$name:}
}
