#!/bin/bash -eux

SOURCEDIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
TERRAFORM_PROJECT_NAME="terraform"
TERRAFORM_PROJECT_PATH="${SOURCEDIR}/../${TERRAFORM_PROJECT_NAME}"
RESULTS_DIRECTORY="${SOURCEDIR}/../results"

export ANSIBLE_PIPELINING=true
export ANSIBLE_SSH_ARGS="-o ForwardX11=no -o UserKnownHostsFile=/dev/null"
export ANSIBLE_SSH_PIPELINING=true
export ANSIBLE_HOST_KEY_CHECKING=false

# Run the ramping up benchmark for the encrypted instance
ansible-playbook \
    -i "${TERRAFORM_PROJECT_PATH}/inventory.yml" \
    -e "@$SOURCEDIR/../environment.yml" \
    -e "@$SOURCEDIR/../credentials.yml" \
    -e "terraform_project_path=${TERRAFORM_PROJECT_PATH}" \
    -e "use_tde=1" \
    "${SOURCEDIR}/playbook-tpcc-run-rampup.yml"

# Run the ramping up benchmark for the unencrypted instance
ansible-playbook \
    -i "${TERRAFORM_PROJECT_PATH}/inventory.yml" \
    -e "@$SOURCEDIR/../environment.yml" \
    -e "@$SOURCEDIR/../credentials.yml" \
    -e "terraform_project_path=${TERRAFORM_PROJECT_PATH}" \
    -e "use_tde=0" \
    "${SOURCEDIR}/playbook-tpcc-run-rampup.yml"

# Run the benchmark for the encrypted and unencrypted instance
ansible-playbook \
    -i "${TERRAFORM_PROJECT_PATH}/inventory.yml" \
    -e "@$SOURCEDIR/../environment.yml" \
    -e "@$SOURCEDIR/../credentials.yml" \
    -e "terraform_project_path=${TERRAFORM_PROJECT_PATH}" \
    -e "results_directory=${RESULTS_DIRECTORY}/report-data" \
    "${SOURCEDIR}/playbook-tpcc-run.yml"

# Copy infrastructure.yml and vars.yml
cp "../infrastructure.yml" "$RESULTS_DIRECTORY"
cp "../credentials.yml" "$RESULTS_DIRECTORY"
