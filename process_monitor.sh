#!/bin/bash

PROCESS_NAME="test"
MONITORING_URL="https://test.com/monitoring/test/api"
LOG_FILE="/var/log/monitoring.log"
STATE_FILE="/var/tmp/monitoring_${PROCESS_NAME}.state"

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $message" | sudo tee -a "$LOG_FILE" > /dev/null
}

check_process() {
    pgrep -x "$PROCESS_NAME" > /dev/null 2>&1
    return $?
}

send_heartbeat() {
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
         --max-time 10 \
         --retry 0 \
         -H "User-Agent: ProcessMonitor/1.0" \
         "$MONITORING_URL" 2>/dev/null)
    local curl_exit_code=$?
    echo "$http_code"
    return $curl_exit_code
}

check_state_change() {
    local current_state="$1"
    local previous_state=""
    if [[ -f "$STATE_FILE" ]]; then
        previous_state=$(cat "$STATE_FILE" 2>/dev/null)
    fi
    echo "${current_state}" | sudo tee "$STATE_FILE" > /dev/null
    if [[ "$previous_state" != "$current_state" ]]; then
        if [[ "$current_state" == "running" ]]; then
            log_message "PROCESS_STARTED - Process '$PROCESS_NAME' was started"
        elif [[ "$previous_state" == "running" ]]; then
            log_message "PROCESS_STOPPED - Process '$PROCESS_NAME' was stopped"
        fi
        return 0
    fi
    return 1
}

main() {
    sudo touch "$LOG_FILE" 2>/dev/null
    sudo chmod 644 "$LOG_FILE" 2>/dev/null
    if check_process; then
        check_state_change "running"
        local http_code
        http_code=$(send_heartbeat)
        local curl_exit_code=$?
        if [[ $curl_exit_code -ne 0 ]] || [[ ! "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
            log_message "MONITORING_ERROR - Server unavailable (HTTP: ${http_code:-"NO_RESPONSE"}, Curl exit: $curl_exit_code)"
        fi
    else
        check_state_change "stopped"
    fi
}

main "$@"
