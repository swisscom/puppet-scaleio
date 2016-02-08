# manage a lia
class scaleio::lia{

  include ::scaleio

  if $scaleio::version !~ /^absent|installed|latest|present$/ {
    $real_version = "-$scaleio::version"
  } else {
    $real_version = ''
  }

  # only versionlock package
  package::verifiable{'EMC-ScaleIO-lia':
    version        => $scaleio::version,
    manage_package => false
  }

  # Setting environment variables is not supported by package
  # but this is needed for setting the LIA password
  exec {"yum install -y 'EMC-ScaleIO-lia$real_version'":
    environment => [ "TOKEN=$scaleio::password" ],
    tag         => 'scaleio-install',
    unless      => "rpm -q 'EMC-ScaleIO-lia$real_version'",
    require     => Package::Yum::Versionlock['EMC-ScaleIO-lia']
  }

  tidy { '/opt/emc/scaleio/lia/rpm':
    age     => '1w',
    recurse => true,
    matches => [ '*rpm' ]
  }
}
