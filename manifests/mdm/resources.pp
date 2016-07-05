# create the scaleio resources a primary mdm
class scaleio::mdm::resources(
  $purge_protection_domains = $scaleio::purge,
  $purge_storage_pools = $scaleio::purge,
  $purge_sds = $scaleio::purge,
  $purge_sdcs = $scaleio::purge,
  $purge_volumes = $scaleio::purge,
) inherits scaleio {

  create_resources('scaleio_user',
    $scaleio::users,
    { ensure => present }
  )

  scaleio_protection_domain{
    $scaleio::protection_domains:
      ensure => present,
  }

  create_resources('scaleio_storage_pool',
    $scaleio::storage_pools,
    { ensure => present }
  )

  create_resources('scaleio_sds',
    $scaleio::sds,
    merge($scaleio::sds_defaults, {
      ensure        => present,
      useconsul     => $scaleio::use_consul,
      ramcache_size => 128 + 0
    })
  )

  create_resources('scaleio_sdc',
    $scaleio::sdcs,
    { ensure => present }
  )

  create_resources('scaleio_volume',
    $scaleio::volumes,
    { ensure => present }
  )

  # Set value when all volumes have been created
  if $scaleio::use_consul {
    Scaleio_volume<| |> ->
    consul_kv{ "scaleio/${::scaleio::system_name}/cluster_setup/primary":
      value => 'ready',
    }
  }

  # Make sure that the sdc are named before trying to map the volumes to those names
  # This cannot be done with autorequire in the provider as the unique name of the resource 'scaleio_sdc' must be the IP and not the name
  Scaleio_sds<| |> -> Scaleio_sdc<| |>
  Scaleio_sdc<| |> -> Scaleio_volume<| |>

  # enable/disable the purging for certain resources
  resources {
    'scaleio_protection_domain':
      purge   => $purge_protection_domains;
    'scaleio_storage_pool':
      purge   => $purge_storage_pools;
    'scaleio_sds':
      purge   => $purge_sds;
    'scaleio_sdc':
      purge   => $purge_sdcs;
    'scaleio_volume':
      purge   => $purge_volumes;
  }
}
