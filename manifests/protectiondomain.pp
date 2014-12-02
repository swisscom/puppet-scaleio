# manage the protectiondomain
class scaleio::protectiondomain(
  $pdomain = $title,
) {

  # Only on Primary
  notify{'pdo module is executed':}
  scaleio_protectiondomain{$pdomain:}
}
