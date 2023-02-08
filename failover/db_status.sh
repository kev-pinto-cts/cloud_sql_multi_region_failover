#!/bin/bash

PROJECT=$1
PRIMARY_INSTANCE=$2
READ_REPLICA=$3

gcloud sql instances describe ${PRIMARY_INSTANCE} --format="table[box,title='✨ Primary Instance:${PRIMARY_INSTANCE} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,replicaNames,settings.tier)"
gcloud sql instances describe ${READ_REPLICA} --format="table[box,title='✨ Read Replica:${READ_REPLICA} ✨'](name,region,gceZone,settings.availabilityType,databaseVersion,connectionName,state,settings.tier)"

