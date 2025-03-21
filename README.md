# Konnichiwa

A simple API to greet you in Japanese.

## Overview

Konnichiwa is a Python-based API service designed to provide basic system information and a greeting. It features three endpoints:

* `/`: Returns a simple greeting.
* `/health`: Provides a health check endpoint, returning "ok" when the service is operational.
* `/inspect`: Returns a JSON response containing detailed system information (CPU usage, memory usage, uptime, etc.). This endpoint is secured with API key authentication to restrict access.

## Running the application locally

1. Instal the following development requirements in your system:
- Python 3.13.2
- Poetry 2.1.1
2.  In the project root directory, create a `.env` file and set the `API_KEY` environment variable.
3.  Install dependencies: `poetry install`
4.  Run the application:
```bash
poetry run uvicorn src.api.main:app --port 4000 --reload
```

## Running Tests
```bash
poetry run pytest
```

## Formatting Code
```bash
poetry run black .
```

## Testing the API
```bash
curl -v http://localhost:4000

curl -H "Authorization: Bearer <THE_API_KEY>" http://127.0.0.1:4000/inspect --
```