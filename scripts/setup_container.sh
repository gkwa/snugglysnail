#!/bin/bash
# Setup the Neo4j container

source ./config/neo4j_config.sh

# Remove any existing container named neo4j
echo "Setting up Neo4j in an Ubuntu 22.04 container..."
incus rm --force ${CONTAINER_NAME} 2>/dev/null || true

# Launch a new Ubuntu 22.04 container
incus launch ${BASE_IMAGE} ${CONTAINER_NAME}

# Create directories for scripts in container
incus exec ${CONTAINER_NAME} -- mkdir -p /root/scripts /root/setup_scripts

# Push the setup script to the container
incus file push ${SETUP_SCRIPT_PATH} ${CONTAINER_NAME}${CONTAINER_SCRIPT_PATH}

# Push all setup scripts to the container
incus file push -r setup_scripts/ ${CONTAINER_NAME}/root/

# Execute the setup script in the container (with SYSTEMD_PAGER empty to avoid paging)
echo "Running installation script in container..."
time incus exec ${CONTAINER_NAME} -- bash -c "SYSTEMD_PAGER= bash ${CONTAINER_SCRIPT_PATH}"
