#!/bin/bash -eux

SOURCEDIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
BENCHMARK_DIRECTORY="$(realpath "${SOURCEDIR}/..")"
ROOT_DIRECTORY="$(realpath "${BENCHMARK_DIRECTORY}/..")"
ANSIBLE_ROLES_PATH="${ROOT_DIRECTORY}/roles"

ANSIBLE_ROLES_PATH=$ANSIBLE_ROLES_PATH \
    ansible-playbook "${SOURCEDIR}/run.yml" \
        -e "root_directory=${ROOT_DIRECTORY}" \
        -e "benchmark_directory=${BENCHMARK_DIRECTORY}"

if (( $(echo "$tpcc_warehouse < 15" | bc -l) )); then
   echo "tpcc_warehouse: $tpcc_warehouse";
   echo "HammerDB Warehouses, cannot be lower than 15!"
   exit 1
fi

if (( $(echo "$tpcc_duration < 15" | bc -l) )); then
   echo "tpcc_duration: $tpcc_duration";
   echo "HammerDB run duration, cannot be lower than 15!"
   exit 1
fi

if (( $(echo "$tpcc_rampup < 15" | bc -l) )); then
   echo "tpcc_rampup: $tpcc_rampup";
   echo "HammerDB RampUp, cannot be lower than 15!"
   exit 1
fi

if (( $(echo "$tpcc_vusers < 15" | bc -l) )); then
   echo "tpcc_vusers: $tpcc_vusers";
   echo "HammerDB Number of virtual users, cannot be lower than 15!"
   exit 1
fi

if (( $(echo "$tpcc_loader_vusers < 15" | bc -l) )); then
   echo "tpcc_loader_vusers: $tpcc_loader_vusers";
   echo "HammerDB Number of Loader virtual users, cannot be lower than 15!"
   exit 1
fi
