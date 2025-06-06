#!/bin/bash
# Create all dependent scripts for Neo4j installation

mkdir -p setup_scripts

# Dependencies installation script
cat <<'EOT' >setup_scripts/install_dependencies.sh
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get -qqy install wget gnupg apt-transport-https ca-certificates curl lsb-release net-tools
EOT

# Java installation script
cat <<'EOT' >setup_scripts/install_java.sh
#!/bin/bash
echo "Installing Java 21..."
if grep -q "jammy\|lunar\|mantic" /etc/os-release; then
  # For Ubuntu 22.04 (jammy) and newer
  apt-get install -y openjdk-21-jdk
else
  # Fallback for older Ubuntu versions
  apt-get install -y software-properties-common
  # Accept license for Oracle Java
  echo debconf shared/accepted-oracle-license-v1-3 select true | debconf-set-selections
  echo debconf shared/accepted-oracle-license-v1-3 seen true | debconf-set-selections
  add-apt-repository -y ppa:linuxuprising/java
  apt-get update
  apt-get install -y oracle-java21-installer
fi

# Verify Java installation
echo "Verifying Java installation:"
java -version
EOT

# Neo4j installation script
cat <<'EOT' >setup_scripts/install_neo4j.sh
#!/bin/bash
# Import Neo4j GPG key
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add -

# Add Neo4j repository
echo 'deb https://debian.neo4j.com stable latest' | tee -a /etc/apt/sources.list.d/neo4j.list

# Update package lists and install Neo4j
apt-get update && apt-get install -y neo4j

# Get public IP address for EC2 (will use this for configuration)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) || PUBLIC_IP=$(hostname -I | awk '{print $1}')

# Configure Neo4j for remote access
echo "Configuring Neo4j for remote access..."

# Create a backup of the original configuration
cp /etc/neo4j/neo4j.conf /etc/neo4j/neo4j.conf.backup

# Update key configuration settings
# Set server to listen on all interfaces
sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/' /etc/neo4j/neo4j.conf

# Set the advertised address to our public IP
sed -i "s/#server.default_advertised_address=localhost/server.default_advertised_address=$PUBLIC_IP/" /etc/neo4j/neo4j.conf

# Ensure HTTP is enabled
sed -i 's/#server.http.enabled=true/server.http.enabled=true/' /etc/neo4j/neo4j.conf
EOT

# Neo4j startup script
cat <<'EOT' >setup_scripts/start_neo4j.sh
#!/bin/bash
# Start Neo4j service
echo "Starting Neo4j service..."
systemctl start neo4j

# Enable Neo4j to start on boot
systemctl enable neo4j

# Wait for Neo4j to become active
echo "Waiting for Neo4j to start..."
MAX_WAIT=120  # Maximum wait time in seconds
start_time=$(date +%s)
while true; do
  if systemctl is-active --quiet neo4j; then
    echo "Neo4j is now active!"
    break
  fi
  
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  
  if [ $elapsed -ge $MAX_WAIT ]; then
    echo "Timed out waiting for Neo4j to start after $MAX_WAIT seconds"
    break
  fi
  
  echo "Waiting for Neo4j to start... ($elapsed seconds elapsed)"
  sleep 5
done

# Check if Neo4j is running properly
if systemctl is-active --quiet neo4j; then
  echo "Neo4j is running!"
else
  echo "Neo4j failed to start properly"
  # Additional diagnostics
  echo "Journal logs:"
  journalctl -u neo4j --no-pager -n 20
fi

# Wait a little more for the HTTP endpoint to be ready
echo "Waiting for Neo4j HTTP endpoint to be available..."
MAX_WAIT_HTTP=60
start_time=$(date +%s)
while true; do
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:7474/ | grep -q "200\|401"; then
    echo "Neo4j HTTP endpoint is available!"
    break
  fi
  
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))
  
  if [ $elapsed -ge $MAX_WAIT_HTTP ]; then
    echo "Timed out waiting for Neo4j HTTP endpoint after $MAX_WAIT_HTTP seconds"
    break
  fi
  
  echo "Waiting for Neo4j HTTP endpoint... ($elapsed seconds elapsed)"
  sleep 3
done

# Display listening ports to verify configuration
echo "Checking listening ports:"
netstat -tulpn | grep -E '7474|7687' || echo "No Neo4j ports found!"

# Test local connectivity
echo "Testing local connectivity:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7474/)
echo "HTTP Status: $HTTP_STATUS"
EOT

# Create shared summary template function
cat <<'EOT' >setup_scripts/display_info.sh
#!/bin/bash
# Get container IP for reporting
IP_ADDR=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) || PUBLIC_IP=$(hostname -I | awk '{print $1}')

# Print summary
echo "==================================================================="
echo "Neo4j installation and configuration complete!"
echo "Container IP: $IP_ADDR"
echo "Public IP (for external access): $PUBLIC_IP"
echo "Access the Neo4j Browser at: http://$PUBLIC_IP:7474/"
echo "Bolt connection: bolt://$PUBLIC_IP:7687"
echo "Default credentials: neo4j:neo4j"
echo "==================================================================="
EOT

# Update the main setup script to use these individual scripts
cat <<'EOT' >setup_neo4j.sh
#!/bin/bash
echo "Starting Neo4j installation..."

# Create scripts directory
mkdir -p /root/scripts

# Copy all setup scripts
cp -r setup_scripts/* /root/scripts/

# Update package repository and install necessary utilities
bash /root/scripts/install_dependencies.sh

# Install Java 21 (required for Neo4j)
bash /root/scripts/install_java.sh

# Install and configure Neo4j
bash /root/scripts/install_neo4j.sh

# Start and verify Neo4j services
bash /root/scripts/start_neo4j.sh

# Display summary information
bash /root/scripts/display_info.sh
EOT
