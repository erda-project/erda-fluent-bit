#!/bin/bash

_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}

_int() {
  echo "Caught SIGINT signal!"
  kill -INT "$child" 2>/dev/null
}

trap _term SIGTERM
trap _int SIGINT

# --- init work block begin ---

# need export for *.conf use
export FLUENTBIT_INPUT_TAIL_EXCLUDE_PATH=${FLUENTBIT_INPUT_TAIL_EXCLUDE_PATH:-'/var/log/containers/*fluent-bit*.log'}
export LOG_LEVEL=${LOG_LEVEL:-'error'}
export MASTER_VIP_URL=${MASTER_VIP_URL:-'https://kubernetes.default.svc:443'}
export FLUENTBIT_THROTTLE_RATE=${FLUENTBIT_THROTTLE_RATE:-1000}
export FLUENTBIT_THROTTLE_RETAIN=${FLUENTBIT_THROTTLE_RETAIN:-'true'}
export FLUENTBIT_THROTTLE_PRINT_STATUS=${FLUENTBIT_THROTTLE_PRINT_STATUS:-'false'}

# used -r in current file
DICE_IS_EDGE=${DICE_IS_EDGE:-'false'} # not used -r in conf files, no need to export
CONFIG_FILE=${CONFIG_FILE:-'/fluent-bit/etc/ds/fluent-bit.conf'}
if [ -z "${COLLECTOR_URL}" ]; then
  if [ "$DICE_IS_EDGE" == "true" ]; then
    if [ -z "${COLLECTOR_PUBLIC_URL}" ]; then
      echo "env COLLECTOR_PUBLIC_URL unset!"
      exit 1
    fi
    COLLECTOR_URL="$COLLECTOR_PUBLIC_URL"
  else
    if [ -z "${COLLECTOR_ADDR}" ]; then
      echo "env COLLECTOR_ADDR unset!"
      exit 1
    fi
    COLLECTOR_URL="http://$COLLECTOR_ADDR"
  fi
fi

container_runtime=${DICE_CONTAINER_RUNTIME:-'docker'} # select runtime's specific config
runtime_parser=""
if [ "$container_runtime" == "docker" ]; then
  runtime_parser='docker'
elif [ "$container_runtime" == "containerd" ]; then
  runtime_parser='cri'
else
  echo "invaild DICE_CONTAINER_RUNTIME=$container_runtime"
  exit 1
fi
export DICE_CONTAINER_RUNTIME="$container_runtime"
echo "DICE_CONTAINER_RUNTIME: $DICE_CONTAINER_RUNTIME"
export RUNTIME_PARSER="$runtime_parser"
echo "RUNTIME_PARSER: $RUNTIME_PARSER"

# extract the protocol
proto="$(echo "$COLLECTOR_URL" | grep '://' | sed -e 's,^\(.*://\).*,\1,g')"

# remove the protocol -- updated
url=$(echo $COLLECTOR_URL | sed -e s,$proto,,g)

# extract the user (if any)
#user="$(echo $url | grep @ | cut -d@ -f1)"

# extract the host and port -- updated
hostport=$(echo $url | sed -e s,$user@,,g | cut -d/ -f1)

# by request host without port
host="$(echo $hostport | sed -e 's,:.*,,g')"
# by request - try to extract the port
port="$(echo $hostport | grep ':' | sed -r -e 's,^.*:,:,g' -e 's,.*:([0-9]*).*,\1,g' -e 's,[^0-9],,g')"

# extract the path (if any)
#path="$(echo $url | grep / | cut -d/ -f2-)"

if [ -z ${port} ]; then
  if [ $proto == 'http://' ]; then
    port=80
  elif [ $proto == 'https://' ]; then
    port=443
  else
    port='unknown'
  fi
fi

# tls config
if [ -z ${OUTPUT_HTTP_TLS} ]; then
  if [ $proto == 'https://' ]; then
    export OUTPUT_HTTP_TLS='On'
  else
    export OUTPUT_HTTP_TLS='Off'
  fi
fi

# local debug
export LOCAL_DEBUG="${LOCAL_DEBUG:-'false'}"

export COLLECTOR_PORT=$port
export COLLECTOR_HOST=$host

echo 'LOCAL_DEBUG: '$LOCAL_DEBUG
echo 'LOG_LEVEL: '$LOG_LEVEL
echo 'COLLECTOR_PORT: '$COLLECTOR_PORT
echo 'COLLECTOR_HOST: '$COLLECTOR_HOST
echo 'OUTPUT_HTTP_TLS: '$OUTPUT_HTTP_TLS
echo "CONFIG_FILE: "$CONFIG_FILE

# --- init work block end ---

FLUENTBIT_BIN_PATH="${FLUENTBIT_BIN_PATH:-/fluent-bit/bin/fluent-bit}"
${FLUENTBIT_BIN_PATH} -c $CONFIG_FILE &

child=$!
wait "$child"
