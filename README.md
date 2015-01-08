# scaleio

## Overview

This module manages EMC ScaleIO deployments, configuration and management of ScaleIO components. Currently it is being able to automate ScaleIO 1.30/1.31 installations.

### Module Description

The EMC ScaleIO module installs and configures ScaleIO clusters and contains providers that manage ScaleIO Clusters, Protection Domains, SDSs and volumes.

## Setup

### Beginning with EMC ScaleIO

**ScaleIO rpms must be available within a yum repository, so that it can be installed using yum. Configuring and managing that repository is not part of the scope of this module**

ScaleIO installations comprise the following components:
* ScaleIO Data Servers (SDS)
* ScaleIO Data Clients (SDC)
* Meta Data Managers (MDM)
* Tie-Breaker Server (TB)
* Callhome

A typical ScaleIO installation comprises Primary and Secondary MDM nodes, a Tie-Breaker node, and multiple SDS and SDC nodes.
A minimal install of a ScaleIO cluster requires all the above-listed components and a minimum of three SDS nodes.
To use these modules to install a minimal 3 node ScaleIO cluster a sample manifest file would look like the sample below, where scaleio1 is the primary MDM node, scaleio2 is the Secondary MDM node and scaleio3 is the Tie-Breaker node. The ScaleIO cluster configuration portion is run only successfully when both the Secondary MDM and the Tie-Breaker nodes have been installed. Which means that you might want to install the TB and secondary MDM node first.

```yaml
scaleio::version: 1.31-256.2.el7
scaleio::components: [sds, sdc]
scaleio::callhome: true
scaleio::primary_mdm_ip: 10.0.0.11
scaleio::secondary_mdm_ip: 10.0.0.12
scaleio::tb_ip: 10.0.0.13
scaleio::password: PW
scaleio::system_name: scaleio
scaleio::callhome_password: PW
scaleio::mdm::callhome::customer_name: 'Swisscom AG'
scaleio::mdm::callhome::from_mail: 'from@test.com'
scaleio::mdm::callhome::to_mail: 'mymail@test.com'
scaleio::mdm::callhome::mail_server_address: 'mail.server.test.com'

scaleio::protection_domains: {pdo1: {}}

scaleio::storage_pools:
  'pdo1:pool1':
    spare_policy: 20%

scaleio::sds:
  'sds-1':
    protection_domain: 'pdo1'
    ips: ['10.0.0.11']
    pool_devices:
      'pool1': ['/dev/sdb']
  'sds-2':
    protection_domain: 'pdo1'
    ips: ['10.0.0.12']
    pool_devices:
      'pool1': ['/dev/sdb']
  'sds-3':
    protection_domain: 'pdo1'
    ips: ['10.0.0.13']
    pool_devices:
      'pool1': ['/dev/sdb']
  'sds-4':
    protection_domain: 'pdo1'
    ips: ['10.0.0.14']
    pool_devices:
      'pool1': ['/dev/sdb']                                                                                                                            
  'sds-5':                                                                                                                                             
    protection_domain: 'pdo1'                                                                                                                          
    ips: ['10.0.0.15']                                                                                                                              
    pool_devices:                                                                                                                                      
      'pool1': ['/dev/sdb']  
      
scaleio::sdc_names:                                                                                                                                    
  '10.0.0.11':                                                                                                                                      
    desc: 'sdc-1'                                                                                                                                      
  '10.0.0.12':                                                                                                                                      
    desc: 'sdc-2'                                                                                                                                      
  '10.0.0.13':                                                                                                                                      
    desc: 'sdc-3'                                                                                                                                      
  '10.0.0.14':                                                                                                                                      
    desc: 'sdc-4'                                                                                                                                      
  '10.0.0.15':
    desc: 'sdc-5'
    
scaleio::volumes:
  'vol1':
    protection_domain: 'pdo1'
    storage_pool: 'pool1'
    size: 24
    type: 'thin'
    sdc_nodes: ['sdc-1', 'sdc-2', 'sdc-3', 'sdc-4', 'sdc-5']

```

For more information on ScaleIO configuration and installation procedures, visit http://support.EMC.com

## Limitations - OS Support, etc.

This module supports the RedHat/CentOS version of ScaleIO in physical and/or VMware environments.  The table below outlines specific OS requirements for ScaleIO versions.


| ScaleIO Version  | Minimum Supported Linux OS |
| ---------------- | ------------------ |
| 1.30/1.31        | CentOS 6.5 / Red Hat 6.5 / CentOS 7.0 / Red Hat 7.0         |

## Puppet Supported Versions

This module requires a minimum version of Puppet 3.7.0 or Puppet Enterprise 3.2.0.