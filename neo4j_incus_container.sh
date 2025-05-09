#!/bin/bash
# Main script to set up a Neo4j container using incus

# Source configuration variables
source ./config/neo4j_config.sh

# Generate the installation script
bash ./scripts/generate_installation_script.sh

# Setup the container
bash ./scripts/setup_container.sh

# Configure network access
bash ./scripts/configure_network.sh

# Print summary information
bash ./scripts/print_summary.sh
