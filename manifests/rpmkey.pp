# Manage the ScaleIO RPM key
class scaleio::rpmkey {
  file {
    '/etc/pki/rpm-gpg/RPM-GPG-KEY-ScaleIO' :
      source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
      owner  => 'root',
      group  => '0',
      mode   => '0644',
  } ~>
  exec { 'scaleio::rpmkey::import' :
    command     => '/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-ScaleIO',
    refreshonly => true,
  }
}
