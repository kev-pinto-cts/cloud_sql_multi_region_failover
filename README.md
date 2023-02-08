# Connecting to Cloud SQL - Postgres
The Following Scripts are to be used for Cloud SQL Failover
This assumes that there already is a CloudSQL instance in Region1 with a Read Replica in Region2.
For Cost Savings ensure that the Read Replica in Region2 is not HA

### Before you begin
Kindly edit the following Values in your Makefile
PROJECT=<UPDATEME>
PRIMARY_REGION=<UPDATEME> example: europe-west2
FAILOVER_REGION=<UPDATEME> example: europe-west2
PRIMARY_INSTANCE=<UPDATEME> Name of the Cloud Instance
READ_REPLICA=<UPDATEME> Name of the Read Replica
MAINTENANCE_WINDOW_DAY=<UPDATEME> example: SUN
MAINTENANCE_WINDOW_HOUR=<UPDATEME> example: 03
BACKUP_START_TIME=<UPDATEME> example: 02:00



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
The `make status` command shows an output as shown below
<p align="left"> 
  <img src="./readme_images/make_status.png" width="1000px" height="400px">
</p>


