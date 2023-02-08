#!/bin/bash

PROJECT=$1
PRIMARY_INSTANCE=$2
READ_REPLICA=$3
REPLICA_REGION=$4

gcloud sql instances describe ${PRIMARY_INSTANCE} \
--format="table[box,title='✨ Primary Instance:${PRIMARY_INSTANCE} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"

echo ""
echo "************ DR Read Replica Script **********************************"
echo "The Script is about to do the following:"
echo "* Clean Up any Instance with the Name: ${READ_REPLICA} in Project: ${PROJECT}"
echo "* Create a Read Replica:(${READ_REPLICA}) for Instance:${PRIMARY_INSTANCE} in Region ${REPLICA_REGION}"
read -p  'These actions are Permanent - Do you wish to continue(Y/N):' response


if [ "${response}" = "Y" ] || [ "${response}" = "y" ]; then
  # Delete Original Primary with Same Name as Replica
  start=$(date +%s)
  gcloud sql instances patch ${READ_REPLICA} --activation-policy NEVER --quiet
  gcloud sql instances delete ${READ_REPLICA} --quiet
  end=$(date +%s)
  echo "Instance ${READ_REPLICA} deleted, Elapsed Time: $(($end-$start)) seconds"

  # Create Replica
  start=$(date +%s)
  gcloud beta sql instances create ${READ_REPLICA} --master-instance-name=${PRIMARY_INSTANCE} --availability-type=ZONAL --region=${REPLICA_REGION}
  end=$(date +%s)
  echo "Read Replica ${READ_REPLICA} created, Elapsed Time: $(($end-$start)) seconds"

  gcloud sql instances describe ${PRIMARY_INSTANCE} \
  --format="table[box,title='✨ Primary Instance:${PRIMARY_INSTANCE} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"

  gcloud sql instances describe ${READ_REPLICA} \
  --format="table[box,title='✨ Read Replica Instance:${READ_REPLICA} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames)"
else
  echo "Skipping Read Replica Setup and Exiting !"
fi
