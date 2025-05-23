#!/bin/bash

log () {
    local TIMESTAMP=$(date +"%Y-%m-%d %T.%3N")
    # Check to make sure pod doesn't terminate if PID value is empty for any reason
    if [ -n "$pid" ]; then
        echo "${TIMESTAMP} $@" > /proc/$pid/fd/1
    fi
}

pid=$(pgrep -fn start.marklogic)

# Check if ML service is running. Exit with 1 if it is other than running
ml_status=$(/etc/init.d/MarkLogic status)

if [[ "$ml_status" =~ "running" ]]; then
    http_code=$(curl -o /tmp/probe_response.txt -s -w "%{http_code}" "http://${HOSTNAME}:8001/admin/v1/timestamp")
    curl_code=$?
    http_resp=$(cat /tmp/probe_response.txt)

    if [[ $curl_code -ne 0 && $http_code -ne 401 ]]; then
        log "Info: [Liveness Probe] Error with MarkLogic"
        log "Info: [Liveness Probe] Curl response code: "$curl_code
        log "Info: [Liveness Probe] Http response code: "$http_code
        log "Info: [Liveness Probe] Http response message: "$http_resp 
    fi
    rm -f /tmp/probe_response.txt
    exit 0
else
    exit 1
fi