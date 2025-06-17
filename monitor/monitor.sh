#!/usr/bin/env bash

set -euo pipefail


# Called on any script exit.
cleanup() {
    # The exit_code of the script is passed as an argument to the trap
    local exit_code=$?
    # Add cleanup logic here, e.g. deleting temp files.
    # echo "Script exiting."
    # Preserve the original exit code
    exit $exit_code
}


# Called on any command failure.
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo "Error: command failed on line ${line_number} with exit code ${exit_code}." >&2
}

# --- Traps ---
# 1. Register the 'handle_error' function to run on the ERR signal.
#    The '$LINENO' variable contains the line number where the error occurred.
trap 'handle_error $LINENO' ERR

# 2. Register the 'cleanup' function to run on the EXIT signal.
#    This ensures cleanup happens regardless of how the script terminates.
trap cleanup EXIT


set -a
source ../.env
set +a

# check if API_KEY is defined
if [[ -z "${API_KEY:-}" ]]; then
  echo "Error: The API_KEY environment variable is not set." >&2
  exit 1
fi

api_key=${API_KEY}

hostname="${KONNICHIWA_HOSTNAME:-localhost}"
port="${KONNICHIWA_PORT:-4000}"

inspect_url="http://${hostname}:${port}/inspect"


# --fail: exit if the HTTP status is an error (>=400)
response=$(curl --fail -s -H "Authorization: Bearer ${api_key}" ${inspect_url})

# Get used CPU and memory percentages from the response
cpu=$(echo "${response}" | jq .system.cpu_used_percent)
mem=$(echo "${response}" | jq .system.memory_used_percent)

if [ "$cpu" -gt 70 ] || [ "$mem" -gt 70 ]; then
    echo "Warning: running low on resource"
else
    echo "Resource use is healthy"
fi
