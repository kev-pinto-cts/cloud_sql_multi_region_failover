# Cloud SQL Multi Region Failover and Failback

## Normal Operations View

![ScreenShot](https://raw.github.com/kev-pinto-cts/cloud_sql_multi_region_failover/main/readme_images/normal_ops.png)


## Description
The Following Scripts are to be used for Cloud SQL Failover
This assumes that there already is a CloudSQL instance in Region1 with a Read Replica in Region2.
For Cost Savings ensure that the Read Replica in Region2 is not HA

### Before you begin
Kindly edit the following Values in your Makefile

```bash
PROJECT=<UPDATEME>
PRIMARY_REGION=<UPDATEME> example: europe-west2
FAILOVER_REGION=<UPDATEME> example: europe-west2
PRIMARY_INSTANCE=<UPDATEME> Name of the Cloud Instance
READ_REPLICA=<UPDATEME> Name of the Read Replica
MAINTENANCE_WINDOW_DAY=<UPDATEME> example: SUN
MAINTENANCE_WINDOW_HOUR=<UPDATEME> example: 03
BACKUP_START_TIME=<UPDATEME> example: 02:00
```


### Make commands
The entire process is driven by a make file
type `make` in the root folder to get a help menu as below

```bash
help                           This is help
init                           Update gcloud
failover                       Failover to Read Replica - use in event of Regional Failover
failover_replica               Create a Read Replica to the newly promoted Primary
failback                       Failback to the Original Primary
status                         Output the Current State of the Deployment
```

### make status
The `make status` command shows an output as shown below - Use this command to know the current state of the Deployment
```bash
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                    ✨ Primary Instance:demo ✨                                                                     │
├──────┬──────────────┬────────────────┬───────────────────┬──────────────────┬────────────────────────────────────┬──────────┬──────────────────┬───────────────────┤
│ NAME │    REGION    │    GCE_ZONE    │ AVAILABILITY_TYPE │ DATABASE_VERSION │          CONNECTION_NAME           │  STATE   │  REPLICA_NAMES   │        TIER       │
├──────┼──────────────┼────────────────┼───────────────────┼──────────────────┼────────────────────────────────────┼──────────┼──────────────────┼───────────────────┤
│ demo │ europe-west2 │ europe-west2-c │ REGIONAL          │ POSTGRES_14      │ cloudsqlpoc-xxxx:europe-west2:demo │ RUNNABLE │ ['demo-replica'] │ db-custom-4-26624 │
└──────┴──────────────┴────────────────┴───────────────────┴──────────────────┴────────────────────────────────────┴──────────┴──────────────────┴───────────────────┘
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                 ✨ Read Replica:demo-replica ✨                                                                 │
├──────────────┬──────────────┬────────────────┬───────────────────┬──────────────────┬────────────────────────────────────────────┬──────────┬───────────────────┤
│     NAME     │    REGION    │    GCE_ZONE    │ AVAILABILITY_TYPE │ DATABASE_VERSION │              CONNECTION_NAME               │  STATE   │        TIER       │
├──────────────┼──────────────┼────────────────┼───────────────────┼──────────────────┼────────────────────────────────────────────┼──────────┼───────────────────┤
│ demo-replica │ europe-west1 │ europe-west1-d │ ZONAL             │ POSTGRES_14      │ cloudsqlpoc-xxxx:europe-west1:demo-replica │ RUNNABLE │ db-custom-4-26624 │
└──────────────┴──────────────┴────────────────┴───────────────────┴──────────────────┴────────────────────────────────────────────┴──────────┴───────────────────┘

```

### make failover
This command Initiates the Failover and Provides the user with a prompt similar to below:
```bash
************ Promote Read Replica  **********************************
The Script is about to do the following:
* Break Replica Link to Primary Instance: demo in Project: cloudsqlpoc-xxxx
* Promote Read Replica:(demo-replica) as the New Primary with **HA Enabled in Region europe-west1**
These actions are Permanent - **Do you wish to continue(Y/N)**
```
On Selecting Y to the Prompt above the following actions are executed:
Please note that this process takes anywhere between **8-10 minutes** - Please make sure this is part of your RTO 

```bash
Breaking Replica Link with Primary: demo....
The following message will be used for the patch API method.
{"name": "demo-replica", "project": "cloudsqlpoc-xxxx", "settings": {"databaseFlags": [{"name": "cloudsql.logical_decoding", "value": "on"}, {"name": "max_connections", "value": "1000"}], "databaseReplicationEnabled": false}}
Patching Cloud SQL instance...done.
Updated [https://sqladmin.googleapis.com/sql/v1beta4/projects/cloudsqlpoc-demo/instances/demo-replica].
Elapsed Time: 51 seconds
Promoting Read Replica: demo-replica....
Promoting a read replica stops replication and converts the instance
to a standalone primary instance with read and write capabilities.
This can't be undone. To avoid loss of data, before promoting the
replica, you should verify that the replica has applied all
transactions received from the primary.

Learn more:
https://cloud.google.com/sql/docs/postgres/replication/manage-replicas#promote-replica

Promoting Cloud SQL replica...⠧
Promoted [https://sqladmin.googleapis.com/sql/v1beta4/projects/cloudsqlpoc-demo/instances/demo-replica].
Elapsed Time: 70 seconds
Patching Read Replica to have Zonal Availability and Configuring Backup and Maintenance Windows
The following message will be used for the patch API method.
{"name": "demo-replica", "project": "cloudsqlpoc-demo", "settings": {"activationPolicy": "ALWAYS", "availabilityType": "REGIONAL", "backupConfiguration": {"backupRetentionSettings": {"retainedBackups": 7, "retentionUnit": "COUNT"}, "enabled": true, "pointInTimeRecoveryEnabled": false, "replicationLogArchivingEnabled": false, "startTime": "02:00", "transactionLogRetentionDays": 7}, "databaseFlags": [{"name": "cloudsql.logical_decoding", "value": "on"}, {"name": "max_connections", "value": "1000"}], "maintenanceWindow": {"day": 7, "hour": 3}}}
Patching Cloud SQL instance...⠼
Updated [https://sqladmin.googleapis.com/sql/v1beta4/projects/cloudsqlpoc-demo/instances/demo-replica].
Elapsed Time: 470 seconds
New Primary Instance demo-replica is Ready ... Kindly Update the App with the Connection Details
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                           ✨ New Primary Instance:demo-replica ✨                                                           │
├──────────────┬──────────────┬────────────────┬───────────────────┬──────────────────┬────────────────────────────────────────────┬──────────┬───────────────┤
│     NAME     │    REGION    │    GCE_ZONE    │ AVAILABILITY_TYPE │ DATABASE_VERSION │              CONNECTION_NAME               │  STATE   │ REPLICA_NAMES │
├──────────────┼──────────────┼────────────────┼───────────────────┼──────────────────┼────────────────────────────────────────────┼──────────┼───────────────┤
│ demo-replica │ europe-west1 │ europe-west1-d │ REGIONAL          │ POSTGRES_14      │ cloudsqlpoc-demo:europe-west1:demo-replica │ RUNNABLE │               │
└──────────────┴──────────────┴────────────────┴───────────────────┴──────────────────┴────────────────────────────────────────────┴──────────┴───────────────┘
```

## Failover View
Notice the following:
1) Link between primary and Read are Broken
2) Read Replica is now HA

At this point the Read Replica is a Completely new Instance and has no connection to the Original Instance (which is down to a Regional Failure)

![ScreenShot](https://raw.github.com/kev-pinto-cts/cloud_sql_multi_region_failover/main/readme_images/failover.png)

Once this is Up, please do the Following:
* Update your cloud sql auth proxy to point to this Instance
* Update any apps that directly reference the instance 
* Create new replication slots and publications in case logical replication was setup on the old primary
