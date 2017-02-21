# manage an scaleio installation
#
# Parameters:
#
# * version: which version to be installed. default: installed (latest in repo)
# * password: for the mdm
# * old_password: if you want to change the password, you have to provide the
#                 old one for change.
# * monitoring_user username for the monitor user
# * monitoring_passwd: password for mionitoring user
# * external_monitoring_user: external monitoring software user (eq splunk user)i that allow running scli cmd for monitoring
# * syslog_ip_port: if set we will configure a syslog server
# * users: scaleio users to be created
#     userName:
#       role     : 'Monitor'   # one of Monitor, Configure, Administrator
#       password : 'myPw'      # pw to be set when creating the account
# * protection_domains: array with names of protection domains to be configured
# * fault_sets array with names of fault sets to be configured
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
#
class scaleio(
  $version                  = 'installed',
  $system_name              = 'my-sio-system',
  $password                 = 'myS3cr3t',
  $old_password             = 'admin',

  $mdms                     = { },
  $tiebreakers              = { },
  $bootstrap_mdm_name       = '',

  $use_consul               = false,

  $users                    = { },
  $protection_domains       = [ ],
  $storage_pools            = { },
  $fault_sets               = [ ],
  $sds                      = { },
  $sds_defaults             = { },
  $sdcs                     = { },
  $volumes                  = { },
  $components               = [],
  $purge                    = false,

  $restricted_sdc_mode      = true,

  $lvm                      = false,
  $syslog_ip_port           = undef,
  $monitoring_user          = 'monitoring',
  $monitoring_passwd        = 'Monitor1',
  $external_monitoring_user = false,
) {

  ensure_packages(['numactl'])

  include ::scaleio::rpmkey

  if $scaleio::use_consul {
    include ::consul
  }

  # extract all local ip addresses of all interfaces
  if $::interfaces {
    $interface_names = split($::interfaces, ',')
    $interfaces_addresses = split(inline_template('<%=
      @interface_names.reject{ |ifc| ifc == "lo" }.map{
        |ifc| scope.lookupvar("ipaddress_#{ifc}")
      }.join(" ")%>'), ' ')


    if ! empty($mdms) {
      if $bootstrap_mdm_name {
        $cluster_setup_ips = any2array($mdms[$bootstrap_mdm_name]['ips'])
        $cluster_setup_ip = $cluster_setup_ips[0]
      }

      # check whether one of the local IPs matches with one of the defined MDM IPs
      # => if so, install MDM on this host
      $mdms_first_ips = scaleio_get_first_mdm_ips($mdms, 'ips')
      $current_mdm_ips = any2array(intersection($mdms_first_ips, $interfaces_addresses))
      $current_mdm_ip = $current_mdm_ips[0]
    }

    if ! empty($tiebreakers) {
      # check whether one of the local IPs matches with one of the defined tb IPs
      # => if so, install tb on this host
      $tbs_first_ips = scaleio_get_first_mdm_ips($tiebreakers, 'ips')
      $current_tb_ips = any2array(intersection($tbs_first_ips, $interfaces_addresses))
      $current_tb_ip = $current_tb_ips[0]
    }
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
  if 'mdm' in $components or has_ip_address($current_mdm_ip) {
    include scaleio::mdm
  }
  if 'tb' in $components or has_ip_address($current_tb_ip) {
    include scaleio::tb
  }
}
