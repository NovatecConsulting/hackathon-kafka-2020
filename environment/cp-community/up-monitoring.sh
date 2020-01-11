#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
source ./docker-compose.sh
source ./ips.sh
CWD_COMPOSE=$(pwd)
popd > /dev/null

function start_service () {
    docker_compose_in_environment up -d $1
}

function add_datasources_in_dir () {
    service_name=${1:?'Missing service name!'}
    datasource_dir=${2:?'Missing datasource directory!'}
    datasource_files=$(find ${datasource_dir}/ -type f)
    for file in ${datasource_files}; do
        add_datasource ${service_name} ${file} || true
    done
}

function add_datasource () {
    service_name=${1:?'Missing service name!'}
    datasource_file=${2:?'Missing datasource file!'}
    grafana_ip=$(ip_of_service ${service_name} 1)
    curl -sL -u admin:admin -X POST -d "@${datasource_file}" -H "Content-Type: application/json" http://${grafana_ip}:3000/api/datasources
}

function add_dashboards_in_dir () {
    service_name=${1:?'Missing service name!'}
    dashboard_dir=${2:?'Missing dashboard directory!'}
    dashboard_files=$(find ${dashboard_dir}/ -type f)
    for file in ${dashboard_files}; do
        add_dashboard ${service_name} ${file} || true
    done
}

function add_dashboard () {
    service_name=${1:?'Missing service name!'}
    dashboard_file=${2:?'Missing dashboard file!'}
    dashboard=$(cat "$dashboard_file")
    dashboard_request="{\"overwrite\": true, \"dashboard\": ${dashboard} }"
    grafana_ip=$(ip_of_service ${service_name} 1)
    curl -sfL -u admin:admin -X POST -d "$dashboard_request" -H 'Content-Type: application/json' http://${grafana_ip}:3000/api/dashboards/db
}


function start_monitoring () {
    start_service "prometheus"
    start_service "grafana"
    sleep 7
    add_datasources_in_dir "grafana" ${CWD_COMPOSE}/configs/grafana/datasource/
    add_dashboards_in_dir "grafana" ${CWD_COMPOSE}/configs/grafana/dashboard/
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    start_monitoring
fi