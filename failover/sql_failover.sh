#!/bin/bash

PROJECT=$1
PRIMARY_REGION=$2
PRIMARY_INSTANCE=$3
READ_REPLICA=$4
MAINTENANCE_WINDOW_DAY=$5
MAINTENANCE_WINDOW_HOUR=$6
BACKUP_START_TIME=$7



decribe_replica_instance() {
  read -r drRegion drZone drName < \
    <(gcloud sql instances describe ${READ_REPLICA} --format="value(region,gceZone,name)")
}

decribe_replica_instance

gcloud sql instances describe ${PRIMARY_INSTANCE} --format="table[box,title='✨ Primary Instance:${PRIMARY_INSTANCE} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"

gcloud sql instances describe ${READ_REPLICA} --format="table[box,title='✨ Read Replica:${READ_REPLICA} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state)"

echo ""
echo "************ Promote Read Replica  **********************************"
echo "The Script is about to do the following:"
echo "* Break Replica Link to Primary Instance: ${PRIMARY_INSTANCE} in Project: ${PROJECT}"
echo "* Promote Read Replica:(${READ_REPLICA}) as the New Primary with HA Enabled in Region ${drRegion}"
read -p  'These actions are Permanent - Do you wish to continue(Y/N):' response

if [ "${response}" = "Y" ] || [ "${response}" = "y" ]; then
  echo "Breaking Replica Link with Primary: ${PRIMARY_INSTANCE}...."
  start=$(date +%s)
  gcloud sql instances patch ${READ_REPLICA} --no-enable-database-replication --quiet
  end=$(date +%s)
  echo "Elapsed Time: $(($end-$start)) seconds"

  echo "Promoting Read Replica: ${READ_REPLICA}...."
  start=$(date +%s)
  gcloud sql instances promote-replica ${READ_REPLICA} --quiet
  end=$(date +%s)
  echo "Elapsed Time: $(($end-$start)) seconds"

  echo "Patching Read Replica to have Zonal Availability and Configuring Backup and Maintenance Windows"
  start=$(date +%s)
  gcloud sql instances patch ${READ_REPLICA} \
    --availability-type REGIONAL \
    --activation-policy ALWAYS \
    --backup-start-time=${BACKUP_START_TIME} \
    --maintenance-window-day=${MAINTENANCE_WINDOW_DAY} \
    --maintenance-window-hour=${MAINTENANCE_WINDOW_HOUR}
  end=$(date +%s)
  echo "Elapsed Time: $(($end-$start)) seconds"

  echo "New Primary Instance ${READ_REPLICA} is Ready ... Kindly Update the App with the Connection Details"
  gcloud sql instances describe ${READ_REPLICA} --format="table[box,title='✨ New Primary Instance:${READ_REPLICA} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"

else
  echo "Skipping Failover and Exiting !"
fi
