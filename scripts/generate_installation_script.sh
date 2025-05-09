#!/bin/bash
# Generate the Neo4j installation script

source ./config/neo4j_config.sh

cat <<'EOT' >setup_neo4j.sh
#!/bin/bash
echo "Starting Neo4j installation..."

# Update package repository and install necessary utilities
bash ./scripts/install_dependencies.sh

# Install Java 21 (required for Neo4j)
bash ./scripts/install_java.sh

# Install and configure Neo4j
bash ./scripts/install_neo4j.sh

# Start and verify Neo4j services
bash ./scripts/start_neo4j.sh

# Display summary information
bash ./scripts/display_info.sh
EOT

# Create the dependent scripts
bash ./scripts/create_dependency_scripts.sh
