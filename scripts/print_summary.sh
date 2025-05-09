#!/bin/bash
# Print summary information

source ./config/neo4j_config.sh

# Get the container IP
CONTAINER_IP=$(get_container_ip)

# Try to get EC2 public IP
PUBLIC_IP=$(get_public_ip)

# Use the shared summary function
generate_summary_text "$CONTAINER_IP" "$PUBLIC_IP" "host"
