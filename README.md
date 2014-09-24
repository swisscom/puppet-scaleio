# scaleio

## Overview

This module manages EMC ScaleIO deployments, configuration and management of ScaleIO components. Currently it is being able to automate ScaleIO 1.3 installations.

### Module Description

The EMC ScaleIO module installs and configures ScaleIO clusters and contains providers that manage ScaleIO Clusters, Protection Domains, SDSs and volumes.

## Setup

### Beginning with EMC ScaleIO

**ScaleIO rpms must be available within a yum repository, so that it can be installed using yum. Configuring and managing that repository is not part of the scope of this module**

ScaleIO installations comprise the following components:
* ScaleIO Data Servers (SDS)
* ScaleIO Data Clients (SDC)
* Meta Data Managers (MDM)
* Tie-Breaker Servers (TB)

A typical ScaleIO installation comprises Primary and Secondary MDM nodes, a Tie-Breaker node, and multiple SDS and SDC nodes.
A minimal install of a ScaleIO cluster requires all the above-listed components and a minimum of three SDS nodes.
To use these modules to install a minimal 3 node ScaleIO cluster a sample manifest file would look like the sample below, where scaleio1 is the primary MDM node, scaleio2 is the Secondary MDM node and scaleio3 is the Tie-Breaker node. The ScaleIO cluster configuration portion is run only successfully when both the Secondary MDM and the Tie-Breaker nodes have been installed. Which means that you might want to install the TB and secondary MDM node first.

The `emcscaleio` class automatically selects the node with the matching ips for the specific components. Additional components can be installed using the components option.

However, it is important to note, that at the moment any sdc component can only be installed *after* the primary MDM have been configured.

```puppet
#
# Setup:
#   scaleio1: 10.0.0.1
#   scaleio2: 10.0.0.2
#   scaleio3: 10.0.0.3
#
node 'scaleio3', 'scaleio2', 'scaleio2'  {
  class {'scaleio':
    primary_mdm_ip    => '10.0.0.1',
    secondary_mdm_ip  => '10.0.0.2',
    tb_ip             => '10.0.0.3'
    components        => ['sds','sdc']
  }
}
```

For more information on ScaleIO configuration and installation procedures, visit http://support.EMC.com

## Limitations - OS Support, etc.

This module supports the RedHat/CentOS version of ScaleIO in physical and/or VMware environments.  The table below outlines specific OS requirements for ScaleIO versions.


| ScaleIO Version  | Minimum Supported Linux OS |
| ---------------- | ------------------ |
| 1.3              | CentOS 6.5 / Red Hat 6.5         |

## Puppet Supported Versions

This module requires a minimum version of Puppet 3.7.0 or Puppet Enterprise 3.2.0.


