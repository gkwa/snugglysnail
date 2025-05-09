#!/bin/bash
# Configuration variables for Neo4j installation

# Container name
CONTAINER_NAME="neo4j"

# Base image for container
BASE_IMAGE="images:ubuntu/22.04/cloud"

# Neo4j ports
HTTP_PORT=7474
BOLT_PORT=7687

# Script paths
SETUP_SCRIPT_PATH="setup_neo4j.sh"
CONTAINER_SCRIPT_PATH="/root/setup_neo4j.sh"

# Get public IP (used in multiple scripts)
get_public_ip() {
    curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "your_host_public_ip"
}

# Get container IP
get_container_ip() {
    incus exec ${CONTAINER_NAME} -- hostname -I | awk '{print $1}'
}

# Function to generate summary text
generate_summary_text() {
    local ip_addr="$1"
    local public_ip="$2"
    local context="$3" # Either "container" or "host"

    echo "==================================================================="
    echo "Neo4j ${context} setup complete!"
    echo "Container IP: ${ip_addr}"
    echo "Public IP (for external access): ${public_ip}"
    echo "Access the Neo4j Browser at: http://${public_ip}:${HTTP_PORT}/"
    echo "Bolt connection: bolt://${public_ip}:${BOLT_PORT}"
    echo "Default credentials: neo4j:neo4j"
    echo "==================================================================="
}
