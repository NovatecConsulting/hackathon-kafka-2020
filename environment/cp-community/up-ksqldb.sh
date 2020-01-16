#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
source ./docker-compose.sh
popd > /dev/null

function start_service () {
    docker_compose_in_environment up -d $1
}

function start_ksqldb () {
    start_service "ksqldb-server"
    start_service "ksqldb-cli"
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    start_ksqldb
fi