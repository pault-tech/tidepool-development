#!/bin/bash
set -e

echo "=== Running Tidepool Devcontainer Setup Script ==="

# 1. Ensure the kube config directory exists
mkdir -p /home/vscode/.kube

# 2. Fix permissions on MongoDB paths in case they were modified
sudo chown -R mongodb:mongodb /var/lib/mongodb /var/log/mongodb

# 3. Start MongoDB Server as background daemon
echo "Starting MongoDB..."
sudo -u mongodb mongod --config /etc/mongod.conf --fork

# 4. Wait for MongoDB to start
echo "Waiting for MongoDB to be ready..."
until mongosh --eval "print(\"MongoDB is up\")" &>/dev/null; do
  sleep 1
done

# 5. Determine Docker gateway IP (typically 172.17.0.1)
DOCKER_IP=$(ip addr show docker0 2>/dev/null | grep -Po 'inet \K[\d.]+' | head -n 1) || true
if [ -z "$DOCKER_IP" ]; then
  # Fallback to default if docker0 is not yet initialized or visible
  DOCKER_IP="172.17.0.1"
fi
echo "Using Docker host gateway IP: $DOCKER_IP"

# 6. Initiate replica set with the Docker gateway IP so Kind containers can connect to it
echo "Initiating replica set 'rs0' with member $DOCKER_IP:27017..."
mongosh --eval "
  try {
    var status = rs.status();
    print('Replica set is already initiated.');
  } catch (e) {
    print('Initiating replica set...');
    var res = rs.initiate({
      _id: 'rs0',
      members: [{ _id: 0, host: '$DOCKER_IP:27017' }]
    });
    print(JSON.stringify(res));
  }
"

# 7. Pre-configure local/Tiltconfig.yaml with host IP for MongoDB if it does not exist
if [ ! -f local/Tiltconfig.yaml ]; then
  echo "Creating local/Tiltconfig.yaml with MongoDB host configuration..."
  mkdir -p local
  cat <<EOF > local/Tiltconfig.yaml
mongo:
  secret:
    data_:
      Addresses: "${DOCKER_IP}"
EOF
else
  echo "local/Tiltconfig.yaml already exists. Skipping auto-configuration of MongoDB address."
fi

# 8. Add tidepool bin to user's PATH if not already present
if ! grep -q "tidepool-development/bin" /home/vscode/.bashrc; then
  echo "Adding /workspaces/tidepool-development/bin to PATH..."
  echo 'export PATH="$PATH:/workspaces/tidepool-development/bin"' >> /home/vscode/.bashrc
fi

echo "=== Setup complete! ==="
