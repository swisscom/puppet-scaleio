# puppet-scaleio
[![Build Status](https://travis-ci.org/swisscom/puppet-scaleio.svg?branch=master)](https://travis-ci.org/swisscom/puppet-scaleio)

This module manages EMC ScaleIO deployments, configuration and management of ScaleIO components. The current version is able to handle ScaleIO 2.0 environments.

This puppet module installs and configures ScaleIO clusters with the following components:

- MDM
- MDM cluster
- SDC
- SDS
- LIA

And it can manage this resources:

- Protection domains
- Fault sets
- Storage pools
- Volumes
- Users
- Syslog destinations

## Cluster installation & configuration
Below you can find the various parameters explained - hiera is taken as an example backend. For sure the same parameters can be passed when declaring the scaleio class.
See [spec/hiera/stack.yaml](spec/hiera/stack.yaml) for a complete hiera example.

The general idea behind the workflow is as follows:

1. Install all components (SDS/SDC/LIA/MDM) on all nodes (one Puppet run per node)
2. Configure the ScaleIO cluster on the primary MDM/bootstrap node and create/manage the specified resources (such as pool, SDS, SDC, etc.)

### ScaleIO packages
It is expected that the following RPM packages are available in a repository so they can be installed with the package manager (ie. yum):

- EMC-ScaleIO-mdm
- EMC-ScaleIO-sdc
- EMC-ScaleIO-sds
- EMC-ScaleIO-lia

### Version locking
The puppet module locks the versions of the RPMs using the yum-versionlock plugin. This prevents an unintended upgrade of the ScaleIO RPMs by running `yum update``

### Components
Per node one or many of the following components can be specified and thus will installed. The MDM component will be installed automatically on the corresponding nodes based on the IP address.
```yaml
scaleio::components: ['sdc', 'sds', 'lia']
```
Note: this is only for installation the appropriate package on the node. The configuration (ie: add it to the cluster) will happen on the primary MDM.

### Bootstrapping
To bootstrap a MDM cluster, one needs to define all MDMs and Tiebreakers.
Moreover the cluster bootstrap node needs to be specified.
The order during the bootstrapping is important, it needs to be as follows:

1. Install all components except MDM primary/bootstrap node, thus
  1. run puppet on secondary MDMs and tiebreakers (install & configure MDM package)
  2. run puppet on all SDS
2. Bootstrap cluster on primary, thus
  1. run puppet on the bootstrap node 

```yaml
scaleio::version: '2.0-6035.0.el7'
scaleio::bootstrap_mdm_name: myMDM1   # node that does the cluster bootstrapping
scaleio::system_name: sysname
scaleio::mdms:
  myMDM1:                             # name of the MDM
    ips: '10.0.0.1'                   # one IP or an array of IPs
    mgmt_ips: '11.0.0.1'              # optional; one IP or an array of IPs
  myMDM2:
    ips: '10.0.0.2'
    mgmt_ips: '11.0.0.2'
  myMDM3:
    ips: '10.0.0.3'
    mgmt_ips: '11.0.0.3'
scaleio::tiebreakers:
  myTB1:
    ips: '10.0.0.4'                   # one IP or an array of IPs
  myTB2:
    ips: '10.0.0.5'
```

#### Consul
This module can make use of an exsting consul cluster to manage the bootstrap ordering.
Thus set the parameter 
```yaml
scaleio::use_consul: true
```
With that all MDMs will create the key `scaleio/${::scaleio::system_name}/cluster_setup/${mdm_tb_ip}` in the consul KV store, as soon as the MDM service is running.
The bootstrap node itself will wait until all MDMs have created their consul key, and then bootstrap the cluster.



### Protection domains
An array of protection domain names.
```yaml
scaleio::protection_domains:
  - 'pdo'
```

### Fault sets
An array of fault set names - the name is splitted by a semicolon (${protection_domain:${fault_set_name}). This parameter is optional:
```yaml
scaleio::fault_sets:
  - 'pdo:FaultSetOne'
  - 'pdo:FaultSetTwo'
  - 'pdo:FaultSetThree'
```

### Storage pools
Besides creating a storage pool, the module supports managing,

- the spare policy,
- the background device scanner,
- enabling/disabling RAM cache on a per-pool basis,
- Activating/deactivating zeropadding

```yaml
scaleio::storage_pools:
  'pdo:pool1':                  # ${protection domain}:${pool name}
    spare_policy: 34%
    ramcache: 'enabled'
    zeropadding: true
    device_scanner_mode: device_only
    device_scanner_bandwidth: 512
  'pdo:pool2':
    spare_policy: 34%
    ramcache: 'disabled'
    zeropadding: false
    device_scanner_mode: disabled
```

### SDS
On a SDS level the following setting are manageable:

- What device belongs to what pool.
- The IPs of the SDS (only one SDS per server supported).
- Size of the RAM cache
- What fault set is the SDS part of? (optional)

To end up with less configuration, there can be defaults specified over all SDS.
In the following example, the configuration would look as follows in the end:

- All SDS are part of the 'pdo' protection domain.
- RAM cache is 128MB (default size) for all SDSs, except for sds-3. There it is disabled.
- /dev/sdb will be part of the storage pool 'pool1' for all SDSs, except for sds-3, there it will be part of 'pool2'.


```yaml
scaleio::sds_defaults:
  protection_domain: 'pdo'
  pool_devices:   
    'pool1':
      - '/dev/sdb'

scaleio::sds:
  'sds-1':
    fault_set: FaultSetOne # optional
    ips: ['192.168.56.121']
  'sds-2':
    fault_set: FaultSetTwo # optional
    ramcache_size: 1024
    ips: ['192.168.56.122']
  'sds-3':
    fault_set: FaultSetThree # optional
    ips: ['192.168.56.123']
    ramcache_size: -1
    pool_devices:   
      'pool2':
        - '/dev/sdb'
```

### SDC
Approve the SDCs and give them a name (desc).
```yaml
scaleio::sdcs:
  '192.168.56.121':
    desc: 'sdc-1'
  '192.168.56.122':
    desc: 'sdc-2'
  '192.168.56.123':
    desc: 'sdc-3'
```

### Volumes
Create ScaleIO volumes and map them to SDCs. The two examples should be self explanatory:
```yaml
scaleio::volumes:
  'volume-1':
    protection_domain: pdo
    storage_pool: pool1
    size: 8
    type: thick
    sdc_nodes:
      - sdc-1
  'volume-2':
    protection_domain: pdo
    storage_pool: pool2
    size: 16
    type: thin
    sdc_nodes:
      - sdc-1
      - sdc-2
```
### Users

Create users and manage their passwords (except the admin user):
```yaml
scaleio::users:
  'api_admin':
    role: 'Administrator'
    password: 'myPassAPI1'
  'monitor_user':
    role: 'Monitor'
    password: 'MonPW123'
```

### General parameters
```yaml
scaleio::version: '2.0-6035.0.el7'          # specific version to be installed
scaleio::password: 'myS3cr3t'               # password of the admin user
scaleio::old_password: 'admin'              # old password of the admin (only required for PW change)
scaleio::use_consul: false                  # use consul for bootstrapping
scaleio::purge: false                       # purge the resources if not defined in puppet parameter (for more granularity, see scaleio::mdm::resources)
scaleio::restricted_sdc_mode: true          # use the restricted SDC mode
scaleio::syslog_ip_port: undef              # syslog destination, eg: 'host:1245'
scaleio::monitoring_user: 'monitoring'      # name of the ScaleIO monitoring user to be created
scaleio::monitoring_passwd: 'Monitor1'      # password of the monitoring user
scaleio::external_monitoring_user: false    # name of a linux user that shall get sudo permissions for scli_wrap_monitoring.sh
```

## Primary MDM switch
The ScaleIO configuration will always take place on the primary MDM. This means if the primary MDM switches, the ScaleIO configuration in the next Puppet run will be applied there.
Exception: bootstrapping. This means if puppet runs on the 'bootstap node' and there is no ScaleIO installed, it will bootstrap a new cluster. 

## ScaleIO upgrade
Proceed with the following steps:

1. Install the 'lia' component on all ScaleIO nodes using this puppet module (`scaleio::components: ['lia']`). 
2. Disable Puppet
3. Upgrade the installation manager
4. Do the actual upgrade using the installation manager
5. Set the correct (new) version (`scaleio::version: XXXX`) for version locking.
6. Enable Puppet again

## scli_wrap
This module uses a script called 'scli_wrap.sh' for executing scli commands. That wrapper script basically does a login, executes the command and does a logout at the end.
To avoid race condition, there is a locking mechanism around those three commands.
As a byproduct this puppet module creates a symlink from /usr/bin/si to that wrapper script and adds bash completion to it. Enjoy running scli commands ;)


## Limitations - OS Support, etc.

The table below outlines specific OS requirements for ScaleIO versions.

| ScaleIO Version | Minimum Supported Linux OS                                      |
|-----------------|-----------------------------------------------------------------|
| 2.0.X           | CentOS ~> 6.5 / Red Hat ~> 6.5 / CentOS ~> 7.0 / Red Hat ~> 7.0 |

Please log tickets and issues at our [Projects site](https://github.com/swisscom/puppet-scaleio/issues)

## Puppet Supported Versions

This module requires a minimum version of Puppet 3.7.0.

MIT license, see [LICENSE.md](LICENSE.md)
