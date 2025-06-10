#!/usr/bin/env python3

import os
import sys

import httpx


cpu_usage_threshold = 70
memory_usage_threshold = 70
hostname = os.getenv("KONNICHIWA_HOSTNAME", "localhost")
port = int(os.getenv("KONNICHIWA_PORT", "4000"))

url = f"http://{hostname}:{port}/inspect"


def is_convertible(variable, target_type):
    try:
        target_type(variable)
        return True
    except (ValueError, TypeError):
        return False


def check_resource_usage():

    # Get API_KEY environment variable
    api_key = os.getenv("API_KEY")
    if not api_key:
        print(f"error: API_KEY environment variable is not set", file=sys.stderr)
        sys.exit(1)

    headers = {"Authorization": f"Bearer {api_key}"}

    try:
        response = httpx.get(url, headers=headers)
        # Raise an exception for 4xx/5xx responses
        response.raise_for_status()
    except httpx.RequestError as e:
        print(f"Error making request to {e.request.url!r}: {e}", file=sys.stderr)
        sys.exit(1)

    system_info = response.json().get("system")
    if not system_info:
        print("Error: 'system' key is missing in the response", file=sys.stderr)
        sys.exit(1)

    # check CPU usage
    cpu_usage = system_info.get("cpu_used_percent")
    if is_convertible(cpu_usage, int):
        cpu_usage = int(cpu_usage)
    else:
        print(f"Error: either cpu_used_percent key is missing or can't convert to int: {cpu_usage}", file=sys.stderr)
        sys.exit(1)

    memory_usage = system_info.get("memory_used_percent")
    if is_convertible(memory_usage, int):
        memory_usage = int(memory_usage)
    else:
        print(f"Error: either cpu_used_percent key is missing or can't convert to int: {memory_usage}", file=sys.stderr)
        sys.exit(1)

    if cpu_usage_threshold < cpu_usage or memory_usage_threshold < memory_usage:
        print(f"Warning: running low on system resource - CPU: {cpu_usage}% used / memory: {memory_usage}")
    else:
        # print(cpu_usage, memory_usage)
        print("Resource usage is healthy at the moment.")


if __name__ == "__main__":
    check_resource_usage()