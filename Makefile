PROJECT=cloudsqlpoc-demo
PRIMARY_REGION=europe-west2
FAILOVER_REGION=europe-west1
PRIMARY_INSTANCE=demo
READ_REPLICA=demo-replica
MAINTENANCE_WINDOW_DAY=SUN
MAINTENANCE_WINDOW_HOUR=03
BACKUP_START_TIME=02:00

# Makefile command prefixes
continue_on_error = -
suppress_output = @

.PHONY: $(shell sed -n -e '/^$$/ { n ; /^[^ .\#][^ ]*:/ { s/:.*$$// ; p ; } ; }' $(MAKEFILE_LIST))

.DEFAULT_GOAL := help

help: ## This is help
	$(suppress_output)awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Update gcloud
	$(suppress_output)gcloud components update

failover: ## Failover to Read Replica - use in event of Regional Failover
	$(suppress_output)echo "Initiating Failover for Instance: ${PRIMARY_INSTANCE} in Project: ${PROJECT}"
	$(suppress_output) bash ./failover/sql_failover.sh \
	${PROJECT} \
	${PRIMARY_REGION} \
	${PRIMARY_INSTANCE} \
	${READ_REPLICA} \
	${MAINTENANCE_WINDOW_DAY} \
	${MAINTENANCE_WINDOW_HOUR} \
	${BACKUP_START_TIME}

failover_replica: ## Create a Read Replica to the newly promoted Primary
	$(suppress_output)echo "Creating Instance Replica in Project:${PROJECT}"
	$(suppress_output) bash ./failover/setup_replica.sh \
	${PROJECT} \
	${READ_REPLICA} \
	${PRIMARY_INSTANCE} \
	${PRIMARY_REGION}


failback: ## Failback to the Original Primary
	$(suppress_output)echo "Creating Deployment Project ${TF_VAR_deployment_project}"
	$(suppress_output)echo "Initiating Failback in Project:${PROJECT}"
	$(suppress_output) bash ./failover/sql_failover.sh \
	${PROJECT} \
	${FAILOVER_REGION} \
	${READ_REPLICA} \
	${PRIMARY_INSTANCE} \
	${MAINTENANCE_WINDOW_DAY} \
	${MAINTENANCE_WINDOW_HOUR} \
	${BACKUP_START_TIME}

failback_replica:
	$(suppress_output)echo "Creating Instance Replica in Project:${PROJECT}"
	$(suppress_output) bash ./failover/setup_replica.sh \
	${PROJECT} \
	${PRIMARY_INSTANCE} \
	${READ_REPLICA} \
	${FAILOVER_REGION}

status: ## Output the Current State of the Deployment
	$(suppress_output) bash ./failover/db_status.sh \
	${PROJECT} \
	${PRIMARY_INSTANCE} \
	${READ_REPLICA}
