#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

URL="https://confluent.cloud"
EMAIL=""
PASSWORD=""

CCLOUD_ENVIRONMENT_NAME="hackathon"

function main () {
    parseCmd "$@"
    local retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi

    readLogin
    loginToConfluentCloud
    retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi

    createCcloudEnv $CCLOUD_ENVIRONMENT_NAME
    retval=$?
    if [ $retval != 0 ]; then
        exit $retval
    fi


 }

function parseCmd () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Confluent Cloud service URL as parameter"
                        return 1
                        ;;
                    *)
                        URL=$1
                        shift
                        ;;
                esac
                ;;
            *)
                usage "Unknown option: $1"
                return 1
                ;;
        esac
    done
    return 0
}

function usage () {
    echo "$0: $1" >&2
    echo
    echo "Usage: $0 [flags]"
    echo -e "\nFlags:"
    echo -e "\t--url string \tConfluent Cloud service URL. (default "https://confluent.cloud")"
    echo
}

function readLogin () {
    if [[ -z "$EMAIL" ]]; then
    read -p "Cloud user email: " EMAIL
    echo ""
    fi
    if [[ -z "$PASSWORD" ]]; then
    read -s -p "Cloud user password: " PASSWORD
    echo ""
    fi
}

function loginToConfluentCloud () {
    echo -e "\n# Login"
    OUTPUT=$(
expect <<END
    log_user 1
    spawn ccloud login --url $URL
    expect "Email: "
    send "$EMAIL\r";
    expect "Password: "
    send "$PASSWORD\r";
    expect "Logged in as "
    set result $expect_out(buffer)
END
    )
    echo "$OUTPUT"
    if [[ ! "$OUTPUT" =~ "Logged in as" ]]; then
        echo "Failed to log into your cluster.  Please check all parameters and run again"
        return 1
    fi
}

function createCcloudEnv () {
    local env_name=${1:-"Missing environment name as first parameter!"}
    echo -e "\n# Create and specify active environment"
    echo "ccloud environment create $env_name"
    ccloud environment create $env_name
    if [[ $? != 0 ]]; then
        echo "Failed to create environment $env_name. Please troubleshoot and run again"
        return 1
    fi
    echo "ccloud environment list | grep $env_name"
    ccloud environment list | grep $env_name
    local env_id=$(ccloud environment list | grep $env_name | awk '{print $1;}')

    echo -e "\n# Specify active environment that was just created"
    echo "ccloud environment use $env_id"
    ccloud environment use $env_id
}

function createCcloudKafkaCluster () {
    local cluster_name=${1:-"Missing Kafka cluster name as first parameter!"}
    echo -e "\n# Create and specify active Kafka cluster"
    echo "ccloud kafka cluster create $cluster_name --cloud azure --region westeurope"
    OUTPUT=$(ccloud kafka cluster create $cluster_name --cloud azure --region westeurope)
    status=$?
    echo "$OUTPUT"
    if [[ $status != 0 ]]; then
    echo "Failed to create Kafka cluster $cluster_name. Please troubleshoot and run again"
    exit 1
    fi
    CLUSTER=$(echo "$OUTPUT" | grep '| Id' | awk '{print $4;}')

    echo -e "\n# Specify active Kafka cluster that was just created"
    echo "ccloud kafka cluster use $CLUSTER"
    ccloud kafka cluster use $CLUSTER
    BOOTSTRAP_SERVERS=$(echo "$OUTPUT" | grep "Endpoint" | grep SASL_SSL | awk '{print $4;}' | cut -c 12-)
    #echo "BOOTSTRAP_SERVERS: $BOOTSTRAP_SERVERS"
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi

