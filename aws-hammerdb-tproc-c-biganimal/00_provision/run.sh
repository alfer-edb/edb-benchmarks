#!/bin/bash -eux

RUNDIR=$(readlink -f "${BASH_SOURCE[0]}")
RUNDIR=$(dirname "$RUNDIR")

TERRAFORM_PROJECT_PATH="${RESULTS_DIRECTORY}/${TERRAFORM_PROJECT_NAME}"
TERRAFORM_PROJECT_PATH=$(readlink -f "${TERRAFORM_PROJECT_PATH}")
TERRAFORM_PLAN_FILENAME="terraform.plan"

# edb-terraform saves a backup of infrastructure.yml in <project-name>/infrastructure.yml.bak
#   this also includes the edb-terraform version used to generate the files
edb-terraform generate --project-name ${TERRAFORM_PROJECT_NAME} \
                       --work-path ${RESULTS_DIRECTORY} \
                       --infra-file ../infrastructure.yml \
                       --cloud-service-provider aws
cd "${TERRAFORM_PROJECT_PATH}"

# .terraform.lock.hcl will be saved here by terraform to lock provider versions and can be reused
terraform init

# Save terraform plan for inspection/reuse
terraform plan -out="$TERRAFORM_PLAN_FILENAME"

# terraform.tfstate/.tfstate.backup will be left around since we use short-term credentials
terraform apply -auto-approve "$TERRAFORM_PLAN_FILENAME"

BIGANIMALINFRAFILE="${TERRAFORM_PROJECT_PATH}/ba-infrastructure.yml"

UNIQUEHASH=$(xxd -l 4 -c 4 -p < /dev/random)

cat >> "${BIGANIMALINFRAFILE}" << EOF
---
clusterArchitecture: single
provider: aws
clusterName: tprocc-${UNIQUEHASH}
password: 1234567890zyx
postgresType: postgres
postgresVersion: "14"
region: us-east-1
instanceType: aws:r5.4xlarge
volumeType: io2
volumeProperties: io2
volumePropertySize: "600 Gi"
volumePropertyIOPS: 15000
networking: public
EOF

# Note that biganimal cli outputs create-cluster messages to stderr.
OUTPUT=$(biganimal create-cluster --cluster-config-file "${BIGANIMALINFRAFILE}" -y 2>&1)
PATTERN='"(.+)"'
[[ $OUTPUT =~ $PATTERN ]]
BAID="${BASH_REMATCH[1]}"

BIGANIMALIDFILE="${TERRAFORM_PROJECT_PATH}/biganimal-id"

echo "$BAID" > "${BIGANIMALIDFILE}"

# TODO: We're only checking if the cluster is healthy.  May need more logic to
# handle other situations or to reply on buildbot to time out after a certain
# amount of time.
RC=0
while [ $RC -ne 1 ]; do
	RC=$(biganimal show-clusters --id "$BAID" | grep "\<$BAID\>" | grep -c "Healthy" || exit 0)
	biganimal show-clusters --id "$BAID"
	sleep 2
done

#
# Manually append servers.yml file with BigAnimal details.
#

TOOMUCHINFO=$(biganimal show-cluster-connection --id "$BAID" | grep read-write)

PATTERN='@(.+):'
[[ $TOOMUCHINFO =~ $PATTERN ]]
BAADDRESS="${BASH_REMATCH[1]}"

PATTERN='postgresql://(.+)@'
[[ $TOOMUCHINFO =~ $PATTERN ]]
BAPGUSER="${BASH_REMATCH[1]}"

cat >> "${TERRAFORM_PROJECT_PATH}/servers.yml" << EOF
  databases:
    tprocc:
      region: us-east-1
      username: "$BAPGUSER"
      password: "1234567890zyx"
      address: $BAADDRESS
      port: 5432
      dbname: "tprocc"
EOF
