# manage an scaleio installation
#
# Parameters:
#
# * version: which version to be installed. default: installed (latest in repo)
# * callhome: should callhome on the mdms be installed?
# * mdm_ips: a list of IPs, which will be mdms. On first setup, the first entry in the list will be the primary mdm. 
#   The initial ScaleIO configuration will be done on this host.
# * tb_ips: a list of IPs, which will be tiebreakers. On first setup, the first entry in the list will be the actively used tb.
# * password: for the mdm
# * old_password: if you want to change the password, you have to provide the
#                 old one for change.
# * monitoring_user username for the monitor user
# * monitoring_passwd: password for mionitoring user
# * external_monitoring_user: external monitoring software user (eq splunk user)i that allow running scli cmd for monitoring
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
#       ramcache          : 'enabled' # or disabled
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
#    - tb
#    - lia
# * lvm: add scini types to lvm.conf to be able to create lvm pv on SIO volumes
# * use_consul: shall consul be used:
#    - to wait for secondary mdm being ready for setup
#    - to wait for tiebreak being ready for setup
#    - to wait for SDSs being ready for adding to cluster
# * restricted_sdc_mode: use restricted SDC mode (true/false)
# * ramcache_size: ram cache size in MB (-1 to disable)
#
class scaleio(
  $version                  = 'installed',
  $system_name              = 'my-sio-system',
  $password                 = 'admin',
  $old_password             = 'admin',

  $mgmt_addresses           = [],
  $mdm_ips                  = [],
  $tb_ips                   = [],

  $callhome                 = false,
  $use_consul               = false,

  $users                    = { },
  $protection_domains       = { },
  $storage_pools            = { },
  $sds                      = { },
  $sdc_names                = { },
  $volumes                  = { },
  $components               = [],
  $purge                    = false,

  $restricted_sdc_mode      = true,
  $ramcache_size            = 128,

  $lvm                      = false,
  $syslog_ip_port           = undef,
  $monitoring_user          = 'monitoring',
  $monitoring_passwd        = 'Monitor1',
  $external_monitoring_user = false,
) {

  ensure_packages(['numactl','python'])

  include ::scaleio::rpmkey

  if $scaleio::use_consul {
    include ::consul
  }

  # extract all local ip addresses of all interfaces
  $interface_names = split($::interfaces, ',')
  $interfaces_addresses = split(inline_template('<%=
    @interface_names.reject{ |ifc| ifc == "lo" }.map{
      |ifc| scope.lookupvar("ipaddress_#{ifc}")
    }.join(" ")%>'), ' ')

  # there must be at least two valid IP addresses
  if ! empty($mdm_ips) {
    validate_re(join($mdm_ips,':_:'), '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}(:_:)?){1,3}$',
      'mdm_ips must be an array with up to 3 valid MDM IPs')

    # check whether one of the local IPs matches with one of the defined MDM IPs
    # => if so, install MDM on this host
    $current_mdm_ip = intersection($mdm_ips, $interfaces_addresses)
  }

  if ! empty($tb_ips) {
    validate_re(join($tb_ips,':_:'), '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}(:_:)?){1,2}$',
      'tb_ips must be an array with up to 2 valid tie-breaker IPs')

    # check whether one of the local IPs matches with one of the defined tb IPs
    # => if so, install tb on this host
    $current_tb_ip = intersection($tb_ips, $interfaces_addresses)
  }

  if 'sdc' in $components {
    include scaleio::sdc
  }
  if 'sds' in $components {
    include scaleio::sds
  }
  if 'lia' in $components {
    include scaleio::lia
  }
  if 'mdm' in $components or (size($current_mdm_ip) >= 1
  and has_ip_address($current_mdm_ip[0])) {
    include scaleio::mdm
  }
  if 'tb' in $components or (size($current_tb_ip) >= 1
  and has_ip_address($current_tb_ip[0])) {
    include scaleio::tb
  }
}
