#!/bin/sh
echo "Running entrypoint.sh..."

influxd

#docker run -d -p 8086:8086 \
#    -e DOCKER_INFLUXDB_INIT_MODE=setup \
#    -e DOCKER_INFLUXDB_INIT_USERNAME="${INFLUXDB_USER}" \
#    -e DOCKER_INFLUXDB_INIT_PASSWORD="${INFLUXDB_PASSWORD}" \
#    -e DOCKER_INFLUXDB_INIT_ORG="${INFLUXDB_ORG}" \
#    -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN="${INFLUXDB_TOKEN}" \
#    -e DOCKER_INFLUXDB_INIT_BUCKET=my_bucket_unused influxdb:2.0
      #-v $PWD/data:/var/lib/influxdb2 \
      #-v $PWD/config:/etc/influxdb2 \
      