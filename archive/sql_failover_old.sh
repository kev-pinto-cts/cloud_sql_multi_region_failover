#!/bin/bash

PROJECT=$1
PRIMARY_REGION=$2
PRIMARY_INSTANCE=$3
READ_REPLICA=$4
MAINTENANCE_WINDOW_DAY=$5
MAINTENANCE_WINDOW_HOUR=$6
BACKUP_START_TIME=$7

# This function is redundant as we cannot extract any Info from the Primary During a Regional Outage
#decribe_primary_instance() {
#  read -r pRegion pZone pName pTier pDiskSizeGb pDiskType pMaintenanceWindowDay pMaintenanceWindowHour pPrimaryIP pBackupStartTime pReplicaNames < \
#    <(gcloud sql instances describe ${PRIMARY_INSTANCE} --format="value(region,gceZone,name,settings.tier,settings.dataDiskSizeGb,settings.dataDiskType,\
#settings.maintenanceWindow.day,settings.maintenanceWindow.hour,ipAddresses,settings.backupConfiguration.startTime, replicaNames)")
#}

decribe_replica_instance() {
  read -r drRegion drZone drName < \
    <(gcloud sql instances describe ${READ_REPLICA} --format="value(region,gceZone,name)")
}

decribe_replica_instance

gcloud sql instances describe ${PRIMARY_INSTANCE} --format="table[box,title='✨ Primary Instance:${PRIMARY_INSTANCE} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"

echo "****************************READ REPLICA:${READ_REPLICA} **************************************************************"
gcloud sql instances describe ${READ_REPLICA} --format="table[box,title='✨ Read Replica:${READ_REPLICA} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state)"

echo "You are attempting to failover from $PRIMARY_INSTANCE in ${PRIMARY_REGION} to ${READ_REPLICA} in ${drRegion}."
read -p 'This is an irreversible action, please type "Y" to proceed: ' acceptance

if [ "$acceptance" = "Y" ] || [ "$acceptance" = "y" ]; then
  echo "Breaking Replica Link with Primary: ${PRIMARY_INSTANCE}...."
  gcloud sql instances patch ${READ_REPLICA} --no-enable-database-replication

  echo "Promoting Read Replica: ${READ_REPLICA}...."
#  gcloud sql instances promote-replica ${READ_REPLICA}

  echo "Patching Read Replica to have Zonal Availability and Configuring Backup and Maintenance Windows"
  gcloud sql instances patch ${READ_REPLICA} \
    --availability-type REGIONAL \
    --activation-policy ALWAYS \
    --backup-start-time=${BACKUP_START_TIME} \
    --maintenance-window-day=${MAINTENANCE_WINDOW_DAY} \
    --maintenance-window-hour=${MAINTENANCE_WINDOW_HOUR}

  echo "New Primary Instance ${READ_REPLICA} is Ready ... Kindly Update the App with the Connection Details"
  gcloud sql instances describe ${READ_REPLICA} --format="table[box,title='✨ New Primary Instance:${READ_REPLICA} ✨](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"

  echo "Stopping Primary Database Instance: ${PRIMARY_INSTANCE}..."
  gcloud sql instances patch ${PRIMARY_INSTANCE} --activation-policy NEVER

  echo "Delete former Primary"
  gcloud sql instances delete ${PRIMARY_INSTANCE}

else
  echo "Skipping Failover and Exiting !"
fi
