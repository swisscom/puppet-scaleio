# manage a datavolume for the scaleio installation
class nc_scaleio::datavg(
  $size = '512M',
  $vg   = $disks::osvg,
) {
  disks::disk_mount{
    'scaleiolv':
      vg            => $vg,
      size          => $size,
      folder        => '/opt/emc',
      manage_folder => false,
      owner         => root,
      group         => root,
      before        => Class['scaleio'],
  }
}
