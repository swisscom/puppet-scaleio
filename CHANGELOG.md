# Changelog

## 3.1.0 [unreleased]
* Add support for fault sets
* Bugfix: Do not fail if bootstrap_mdm_name is undef (ie. on a SDC)

## 3.0.2
* Bugfix: volumes might have no mappings
* Bugfix: SDS might have no devices
* Bugfix: MDMs without mgmt_ips should not lead to a ruby error

## 3.0.1 (2016-07-07)
* Add all MDM IPs to the SDC

## 3.0.0 (2016-07-04)
* ScaleIO 2.0
** module now supports only 2.X and drops support for 1.3X
** refactoring of the whole module and parameters

## 2.2.5 (2016-06-14)
* manage lia service

## 2.2.4 (2016-05-18)
* manage scini service

## 2.2.3 (2016-05-09)
* scaleio does not (yet) support IPv6 endpoints so we need to filter them

## 2.2.2 (2016-03-29)
* ensure that the mdm_failover service is running

## 2.2.1 (2016-03-21)
* Report primary is finished setting up, after all SDC have been configured.

## 2.2.0 (2016-03-21)
* Introduce nc_scaleio::monitoring_user as variable

## 2.1.0 (2016-02-28)
* Allow disabling/enabling RAM read cache per pool

## 2.0.0 (2016-02-04)
* Add lia as installation component
