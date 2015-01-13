# manage an scaleio installation
#
# Parameters:
#
# * version: which version to be installed. default: installed (latest in repo)
# * callhome: should callhome on the mdms be installed?
# * primary_mdm_ip: ip of the primary mdm, if any of the current ips of a host matches this ip, it will be configured as primary mdm
# * secondary_mdm_ip: ip of the secondary mdm, if any of the current ips of a host matches this ip, it will be configured as secondary mdm
# * tb_ip: ip of the tiebreaker, if any of the current ips of a host matches this ip, it will be configured as a tiebreaker
# * password: for the mdm
# * old_password: if you want to change the password, you have to provide the
#                 old one for change.
# * syslog_ip_port: if set we will configure a syslog server
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
class scaleio(
  $version            = 'installed',
  $callhome           = true,
  $primary_mdm_ip     = undef,
  $secondary_mdm_ip   = undef,
  $tb_ip              = undef,
  $license            = undef,
  $password           = 'admin',
  $old_password       = 'admin',
  $syslog_ip_port     = undef,
  $system_name        = undef,
  $purge              = false,
  $users              = {},
  $protection_domains = {},
  $storage_pools      = {},
  $sds                = {},
  $sdc_names          = {},
  $volumes            = {},
  $components         = [],
) {

  ensure_packages(['numactl','python-paramiko'])

  # both must be set and if they are they should be valid
  if $primary_mdm_ip or $secondary_mdm_ip {
    validate_re($primary_mdm_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
    validate_re($secondary_mdm_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
    if $primary_mdm_ip == $secondary_mdm_ip {
      fail('$primary_mdm_ip and $secondary_mdm_ip can\'t be the same!')
    }
  }
  if $tb_ip {
    validate_re($tb_ip, '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$')
  }

  if 'sdc' in $components {
    include scaleio::sdc
  }
  if 'sds' in $components {
    include scaleio::sds
  }
  if 'mdm' in $components or ($primary_mdm_ip and has_ip_address($primary_mdm_ip)) or ($secondary_mdm_ip and has_ip_address($secondary_mdm_ip)) {
    include scaleio::mdm
  }
  if 'tb' in $components or ($tb_ip and has_ip_address($tb_ip)) {
    include scaleio::tb
  }

}
