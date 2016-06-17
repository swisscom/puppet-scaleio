# setup things needed for monitoring
class scaleio::mdm::monitoring(
  $scli_wrap_monitoring = '/opt/emc/scaleio/scripts/scli_wrap_monitoring.sh'
) {
  include ::scaleio

  if $scaleio::external_monitoring_user {
    file{
      $scli_wrap_monitoring:
        content => template('scaleio/scli_wrap_monitoring.sh.erb'),
        owner   => root,
        group   => 0,
        mode    => '0700',
    }
  }
}