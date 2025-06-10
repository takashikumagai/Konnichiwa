#!/usr/bin/env bash

set -euo pipefail

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


response=$(curl -s -H "Authorization: Bearer ${api_key}" ${inspect_url})

# Get used CPU and memory percentages from the response
cpu=$(echo "${response}" | jq .system.cpu_used_percent)
mem=$(echo "${response}" | jq .system.memory_used_percent)

if [ "$cpu" -gt 70 ] || [ "$mem" -gt 70 ]; then
    echo "Warning: running low on resource"
else
    echo "Resource use is healthy"
fi
