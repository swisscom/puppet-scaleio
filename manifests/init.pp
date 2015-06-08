# manage an scaleio installation
#
# Parameters:
#
# * version: which version to be installed. default: installed (latest in repo)
# * callhome: should callhome on the mdms be installed?
# * primary_mdm_ip: ip of the primary mdm, if any of the current ips of a host matches this ip, it will be configured as primary mdm
# * secondary_mdm_ip: ip of the secondary mdm, if any of the current ips of a host matches this ip, it will be configured as secondary mdm
# * tb_ip: ip of the tiebreaker, if any of the current ips of a host matches this ip, it will be configured as a tiebreaker
# * mdm_ips: a list of IPs, which will be mdms. On first setup, the first entry in the list will be the primary mdm. 
#   The initial ScaleIO configuration will be done on this host.
# * tb_ips: a list of IPs, which will be tiebreakers. On first setup, the first entry in the list will be the actively used tb. 
# * password: for the mdm
# * old_password: if you want to change the password, you have to provide the
#                 old one for change.
# * syslog_ip_port: if set we will configure a syslog server
# * mgmt_addresses: array of ip addresses to be configured as SIO management addresses
# * users: scaleio users to be created
#     userName:
#       role     : 'Monitor'   # one of Monitor, Configure, Administrator
#       password : 'myPw'      # pw to be set when creating the account
# * protection_domains: hash with names of protection domains to be configured
# * storage_pools: storage pool to be created/managed, hash looking as follows:
#     myPoolName:
#       protection_domain : myProtectionDomainName
#       spare_policy      : 35%
# * sds: hash containing SDS definitions, format:
#     'sds_name':
#       protection_domain : 'pdomain1',
#       ips               : ['10.0.0.2', '10.0.0.3'],
#       port              : '7072', # optional
#       pool_devices      : {
#         'myPool'  : ['/tmp/aa', '/tmp/ab'],
#         'myPool2' : ['/tmp/ac', '/tmp/ad'],
#       }
# * sdc_names: hash containing SDC names, format:
#     'sdc_ip:
#       desc => 'mySDCname'
# * volumes: hash containing volumes, format:
#     'volName':
#       storage_pool:       'poolName'
#       protection_domain:  'protDomainName'
#       size:               504 # volume size in GB
#       type:               'thin' # either thin or thick
#       sdc_nodes:          ['node1', 'node2'] # array containing SDC names the volume shall be mapped to 
#       
# * purge: shall the not defined resources (f.e. protection domain, storage pool etc.) be purged
# * components: will configure the different components any out of:
#    - sds
#    - sdc
#    - mdm
#    - tb
# * use_consul: shall consul be used:
#    - to wait for secondary mdm being ready for setup
#    - to wait for tiebreak being ready for setup
#    - to wait for SDSs being ready for adding to cluster
#
class scaleio(
  $version            = 'installed',
  $callhome           = true,
  $primary_mdm_ip     = undef,
  $secondary_mdm_ip   = undef,
  $tb_ip              = undef,
  $mdm_ips            = false,
  $tb_ips             = false,
  $license            = undef,
  $password           = 'admin',
  $old_password       = 'admin',
  $syslog_ip_port     = undef,
  $system_name        = undef,
  $purge              = false,
  $mgmt_addresses     = [],
  $users              = {},
  $protection_domains = {},
  $storage_pools      = {},
  $sds                = {},
  $sdc_names          = {},
  $volumes            = {},
  $components         = [],
  $use_consul         = false,
) {

  ensure_packages(['numactl','python'])

  # extract all local ip addresses of all interfaces
  $interface_names = split($::interfaces, ',')
  $interfaces_addresses = split(inline_template('<%=
    @interface_names.reject{ |ifc| ifc == "lo" }.map{ |ifc| scope.lookupvar("ipaddress_#{ifc}") }.join(" ")%>'),
    ' ')

  $real_mdm_ips = $mdm_ips ? {
    false   => [$primary_mdm_ip, $secondary_mdm_ip],
    default => mdm_ips,
  }

  # both must be set and if they are they should be valid
  validate_re($real_mdm_ips[0], '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  validate_re($real_mdm_ips[1], '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  if $real_mdm_ips[0] == $real_mdm_ips[1] {
    fail('$primary_mdm_ip and $secondary_mdm_ip can\'t be the same!')
  }

  $real_tb_ips = $tb_ips ? {
    false   => [$tb_ip],
    default => tb_ips,
  }

  if $real_tb_ips[0] {
    validate_re($real_tb_ips[0], '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  }

  # check whether one of the local IPs matches with one of the defined MDM IPs
  # => if so, install MDM on this host
  $current_mdm_ip = intersection($real_mdm_ips, $interfaces_addresses)
  # check whether one of the local IPs matches with one of the defined tb IPs
  # => if so, install tb on this host
  $current_tb_ip = intersection($real_tb_ips, $interfaces_addresses)

  if 'sdc' in $components {
    include scaleio::sdc
  }
  if 'sds' in $components {
    include scaleio::sds
  }
  if 'mdm' in $components or (size($current_mdm_ip) >= 1 and has_ip_address($current_mdm_ip[0])) {
    include scaleio::mdm
  }
  if 'tb' in $components or (size($current_tb_ip) >= 1 and has_ip_address($current_tb_ip[0])) {
    include scaleio::tb
  }

}