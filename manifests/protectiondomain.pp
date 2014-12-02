# manage the protectiondomain
class scaleio::protectiondomain(
  $name = undef,
) {

  # Only on Primary
  notify{'pdo module is executed':}
  #scaleio_protectiondomain{$name:}
}
