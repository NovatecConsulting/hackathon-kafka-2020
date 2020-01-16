#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
SCRIPT_DIR=$(pwd)
popd > /dev/null

# Script parameters
CCLOUD_URL="https://confluent.cloud"

CCLOUD_RESOURCE_PREFIX=$((1 + RANDOM % 1000000))
CCLOUD_ENVIRONMENT_NAME="hackathon-example"

# Script variables
CLUSTER_ID=""
BOOTSTRAP_SERVERS=""
API_KEY=""

function main () {
    parseCmd "$@"
    if [ $? != 0 ]; then exit 1; fi

    readCCloudLogin
    loginToCCloud
    if [ $? != 0 ]; then exit 1; fi

    createCCloudEnv
    if [ $? != 0 ]; then exit 1; fi

    createCCloudKafkaCluster
    if [ $? != 0 ]; then exit 1; fi

    createCCloudAPIKey
    if [ $? != 0 ]; then exit 1; fi
 }

function parseCmd () {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --url)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires Confluent Cloud service Url as parameter"
                        return 1
                        ;;
                    *)
                        CCLOUD_URL=$1
                        shift
                        ;;
                esac
                ;;
            --prefix)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires resource prefix as parameter"
                        return 1
                        ;;
                    *)
                        CCLOUD_RESOURCE_PREFIX=$1
                        shift
                        ;;
                esac
                ;;
            --name)
                shift
                case "$1" in
                    ""|--*)
                        usage "Requires environment name as parameter"
                        return 1
                        ;;
                    *)
                        CCLOUD_ENVIRONMENT_NAME=$1
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
    echo -e "\t--url string \tConfluent Cloud service Url. (default "https://confluent.cloud")"
    echo -e "\t--prefix string \tPrefix, which is added to all resources (random by default)"
    echo -e "\t--name string \tName of the environment and the Kafka cluster ('hackathon-example' by default)"
    echo
}

function readCCloudLogin () {
    if [[ -z "$CCLOUD_EMAIL" ]]; then
    read -p "Cloud user eMail: " CCLOUD_EMAIL
    echo ""
    fi
    if [[ -z "$CCLOUD_PASSWORD" ]]; then
    read -s -p "Cloud user password: " CCLOUD_PASSWORD
    echo ""
    fi
}

function loginToCCloud () {
    echo -e "\n# Login"
    local output=$(
expect <<END
    log_user 1
    spawn ccloud login --url $CCLOUD_URL
    expect "Email: "
    send "$CCLOUD_EMAIL\r";
    expect "Password: "
    send "$CCLOUD_PASSWORD\r";
    expect "Logged in as "
    set result $expect_out(buffer)
END
    )
    echo "$output"
    if [[ ! "$output" =~ "Logged in as" ]]; then
        echo "Failed to log into your cluster.  Please check all parameters and run again"
        return 1
    fi
}

function createCCloudEnv () {
    local env_name=${CCLOUD_RESOURCE_PREFIX}-${CCLOUD_ENVIRONMENT_NAME}
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

function createCCloudKafkaCluster () {
    local cluster_name=${CCLOUD_RESOURCE_PREFIX}-${CCLOUD_ENVIRONMENT_NAME}-cluster
    echo -e "\n# Create and specify active Kafka cluster"
    echo "ccloud kafka cluster create $cluster_name --cloud gcp --region europe-west3"
    local output=$(ccloud kafka cluster create $cluster_name --cloud gcp --region europe-west3)
    local status=$?
    echo "$output"
    if [[ $status != 0 ]]; then
    echo "Failed to create Kafka cluster $cluster_name. Please troubleshoot and run again"
    exit 1
    fi
    CLUSTER_ID=$(echo "$output" | grep '| Id' | awk '{print $4;}')

    echo -e "\n# Specify active Kafka cluster that was just created"
    echo "ccloud kafka cluster use $CLUSTER_ID"
    ccloud kafka cluster use $CLUSTER_ID
    BOOTSTRAP_SERVERS=$(echo "$output" | grep "Endpoint" | grep SASL_SSL | awk '{print $4;}' | cut -c 12-)
}

function createCCloudAPIKey () {
    echo -e "\n# Create API key for user $CCLOUD_EMAIL and cluster $CLUSTER_ID"
    echo "ccloud api-key create --description \"Demo credentials for user $CCLOUD_EMAIL and cluster $CLUSTER_ID\" --resource $CLUSTER_ID"
    local output=$(ccloud api-key create --description "Demo credentials for user $CCLOUD_EMAIL and cluster $CLUSTER_ID" --resource $CLUSTER_ID)
    local status=$?
    echo "$output"
    if [[ $status != 0 ]]; then
    echo "Failed to create an API key.  Please troubleshoot and run again"
    exit 1
    fi
    API_KEY=$(echo "$output" | grep '| API Key' | awk '{print $5;}')

    echo -e "\n# Specify active API key that was just created"
    echo "ccloud api-key use $API_KEY --resource $CLUSTER_ID"
    ccloud api-key use $API_KEY --resource $CLUSTER_ID
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    main "$@"
fi

