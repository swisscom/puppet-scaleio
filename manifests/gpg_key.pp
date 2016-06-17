# Manage the ScaleIO RPM key
class scaleio::rpmkey {
  file {
    '/etc/pki/rpm-gpg/RPM-GPG-KEY-ScaleIO' :
      source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
      owner  => 'root',
      group  => '0',
      mode   => '0644',
      notify => Exec['scaleio::rpmkey::import']
  }
  exec {
    'scaleio::rpmkey::import' :
      command     => 'rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-ScaleIO',
      refreshonly => true
  }
}
