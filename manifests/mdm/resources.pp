# create the scaleio resources a primary mdm
class scaleio::mdm::resources {

  create_resources('scaleio_user',              $scaleio::users,              {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], File[$scaleio::mdm::add_scaleio_user]]})
  create_resources('scaleio_protection_domain', $scaleio::protection_domains, {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary']})
  create_resources('scaleio_storage_pool',      $scaleio::storage_pools,      {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary']})
  create_resources('scaleio_sds',               $scaleio::sds,                {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary'], useconsul => $scaleio::use_consul, ramcache_size => $scaleio::ramcache_size + 0})
  create_resources('scaleio_sdc_name',          $scaleio::sdc_names,          {ensure => present, require => [Exec['scaleio::mdm::primary_add_secondary'], Exec['scaleio::mdm::manage_sdc_access_restriction']], restricted_sdc_mode => $real_restricted_sdc_mode})
  create_resources('scaleio_volume',            $scaleio::volumes,            {ensure => present, require => Exec['scaleio::mdm::primary_add_secondary']})

  # Make sure that the sdc are renamed before trying to map the volumes to those names
  # This cannot be done with autorequire in the provider as the unique name of the resource 'scaleio_sdc_name' must be the IP and not the name
  Scaleio_sds<| |> -> Scaleio_sdc_name<| |>
  Scaleio_sdc_name<| |> -> Scaleio_volume<| |>

  #resources {
  #  'scaleio_protection_domain':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_storage_pool':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_sds':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_sdc_name':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #  'scaleio_volume':
  #    require => Exec['scaleio::mdm::primary_add_secondary'],
  #    purge => $scaleio::purge;
  #}
}