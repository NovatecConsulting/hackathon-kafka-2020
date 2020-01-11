#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
CWD_COMPOSE=$(pwd)
source ./up-kafka.sh
source ./test-kafka.sh
source ./up-monitoring.sh
source ./ips.sh
popd > /dev/null

MONITORING=false
KAFKA=false

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 [--with-monitoring] all kafka schema-registry connect ksqldb"
    echo
    return 1
}

function parseCmd () {
    local any_selected=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --with-monitoring)
                MONITORING=true
                shift
                ;;
            all)
                any_selected=true
                KAFKA=true
                shift
                ;;
            kafka)
                any_selected=true
                KAFKA=true
                shift
                ;;
            *)
                usage "Unknown option: $1"
                return $?
                ;;
        esac
    done
    if [ "${any_selected}" == false ]; then
        usage "Specifiy at least one service"
        return $?
    fi
    return 0
}

function resolveCommit () {
    pushd . > /dev/null
    cd $CWD_COMPOSE
    git rev-list --abbrev-commit --abbrev=7 -1 master || echo master
    popd > /dev/null
} 

function main () {
    parseCmd "$@"
    local retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi
    
    if [ "$MONITORING" = true ]; then
        start_monitoring
    fi

    if [ "$KAFKA" = true ]; then
        start_kafka ${MONITORING}
        sleep 5
        test_kafka
    fi

    echo -e "\n"
    sed -n -e '/== Network/,$p' ${CWD_COMPOSE}/README.adoc
    echo -e "\n"
    ips_of_all_containers

    echo -e "\nFor detailed information visit https://github.com/NovatecConsulting/technologyconsulting-kafka-hackathon/tree/$(resolveCommit)/environment/cp-community/README.adoc"
}

main "$@"
