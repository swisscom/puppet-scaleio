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
  exec {"yum install EMC-ScaleIO-lia$real_version":
    environment => [ "TOKEN=$scaleio::password" ],
    unless      => "rpm -q EMC-ScaleIO-lia$real_version",
  }->

  # fix require for package verifiable
  package{'EMC-ScaleIO-lia':
    ensure => 'installed'
  }

  tidy { '/opt/emc/scaleio/lia/rpm':
    age     => '1w',
    recurse => true,
    matches => [ '*rpm' ]
  }
}
