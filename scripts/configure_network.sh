#!/bin/bash
# Configure network for Neo4j container

source ./config/neo4j_config.sh

# Configure proxy for access from host
echo "Setting up port forwarding..."
incus config device add ${CONTAINER_NAME} http-proxy proxy listen=tcp:0.0.0.0:${HTTP_PORT} connect=tcp:127.0.0.1:${HTTP_PORT}
incus config device add ${CONTAINER_NAME} bolt-proxy proxy listen=tcp:0.0.0.0:${BOLT_PORT} connect=tcp:127.0.0.1:${BOLT_PORT}
