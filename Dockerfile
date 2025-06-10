FROM python:3.13.2-alpine3.21


### Install dependencies ###

# These are required by psutil
# Also use virtual package for cleanup
RUN apk add --no-cache --virtual .build-deps \
        gcc \
        musl-dev \
        linux-headers

### Create application runner user ###

ENV SERVICE_NAME="konnichiwa"

# Originally there was -H option to skip the creation of user's home directory
# because pip needs it for /home/$SERVICE_NAME/.cache and more
# i.e. passing --cache-dir to pip install didn't do the job
RUN addgroup --gid 1001 -S $SERVICE_NAME && \
    adduser -G $SERVICE_NAME --shell /bin/false --disabled-password --uid 1001 $SERVICE_NAME && \
    mkdir -p /var/log/$SERVICE_NAME && \
    chown $SERVICE_NAME:$SERVICE_NAME /var/log/$SERVICE_NAME


### Install konnichiwa

WORKDIR /app

COPY src /app/src
COPY .python-version /app/
COPY pyproject.toml poetry.lock README.md /app/

RUN chown -R $SERVICE_NAME:$SERVICE_NAME /app

# Create user

USER $SERVICE_NAME

ENV PATH="/home/${SERVICE_NAME}/.local/bin:$PATH"

RUN pip install --user --no-cache-dir --disable-pip-version-check /app

WORKDIR /app/src/api

# Run uvicorn as $SERVICE_NAME
CMD ["gunicorn", "main:app", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:80", "-w", "9"]
