#!/usr/bin/env bash
set -e
pushd . > /dev/null
cd $(dirname ${BASH_SOURCE[0]})
source ./docker-run.sh
source ./env.sh
popd > /dev/null

BOOTSTRAP_SERVER="kafka1:9092,kafka2:9092,kafka3:9092"
REPLICATION_FACTOR=3

function log() {
  local severity=${1:?"Missing severity as first parameter!"}
  local message=${2:?"Missing message as second parameter!"}
  echo "$(date)|${severity}|${message}|"
}

function run_kafka_cmd () {
    docker_run confluentinc/cp-kafka:${VERSION_CONFLUENT} $@
}

function createTopic() {
    local topic=${1:?"Missing topic as first parameter!"}
    log "INFO" "Create topic ${topic}"
    run_kafka_cmd kafka-topics --bootstrap-server ${BOOTSTRAP_SERVER} --create --replication-factor ${REPLICATION_FACTOR} --partitions 1 --topic ${topic}
    local returnCode=$? 
    [ $returnCode -eq 0 ] && log "INFO" "ok" || log "ERROR" "nok|Could not create topic ${topic}"
    return $returnCode
}

function deleteTopic() {
  local topic=${1:?"Missing topic as first parameter!"}
  log "INFO" "Delete topic ${topic}"
  run_kafka_cmd kafka-topics --bootstrap-server ${BOOTSTRAP_SERVER} --delete --topic ${topic}
  local returnCode=$? 
  [ $returnCode -eq 0 ] && log "INFO" "ok" || log "ERROR" "nok|Could not delete topic ${topic}"
  return $returnCode
}

function test_kafka_latency () {
    log "INFO" "Perform latency test"
    local topic=latencytopic
    createTopic ${topic}
    time run_kafka_cmd kafka-run-class kafka.tools.EndToEndLatency ${BOOTSTRAP_SERVER} ${topic} 5000 all 1024
    local returnCode=$?
    [ $returnCode -eq 0 ] && log "INFO" "ok" || log "ERROR" "nok|Failed to perform latency test"
    deleteTopic ${topic}
    return $returnCode
}

function test_kafka_throughput () {
    log "INFO" "Perform producer throughput test"
    local topic=throughputtopic
    createTopic ${topic}
    time run_kafka_cmd kafka-producer-perf-test --topic ${topic} --num-records 20000 --record-size 1024 --throughput -1 --producer-props bootstrap.servers=${BOOTSTRAP_SERVER} retries=3 batch.size=1 max.in.flight.requests.per.connection=1 acks=-1
    local returnCode=$?
    [ $returnCode -eq 0 ] && log "INFO" "ok" || log "ERROR" "nok|ailed to perform producer throughput test"
    deleteTopic ${topic}
    return $returnCode
}

function test_kafka () {
    test_kafka_latency
    test_kafka_throughput
}

if [ "${BASH_SOURCE[0]}" == "$0" ]; then
    test_kafka
fi