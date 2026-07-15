FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

USER root

# Install dependencies and MongoDB repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg \
    curl \
    ca-certificates \
    netcat-openbsd \
    iproute2 \
    sudo \
    && curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    mongodb-org \
    mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

# Configure MongoDB replica set in /etc/mongod.conf
RUN echo "storage:" > /etc/mongod.conf \
    && echo "  dbPath: /var/lib/mongodb" >> /etc/mongod.conf \
    && echo "  journal:" >> /etc/mongod.conf \
    && echo "    enabled: true" >> /etc/mongod.conf \
    && echo "systemLog:" >> /etc/mongod.conf \
    && echo "  destination: file" >> /etc/mongod.conf \
    && echo "  logAppend: true" >> /etc/mongod.conf \
    && echo "  path: /var/log/mongodb/mongod.log" >> /etc/mongod.conf \
    && echo "net:" >> /etc/mongod.conf \
    && echo "  port: 27017" >> /etc/mongod.conf \
    && echo "  bindIp: 0.0.0.0" >> /etc/mongod.conf \
    && echo "replication:" >> /etc/mongod.conf \
    && echo "  replSetName: rs0" >> /etc/mongod.conf

# Install development CLI tools (kubectl, helm, tilt, ctlptl, kind, glooctl)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
      KUBECTL_ARCH="amd64"; \
      HELM_ARCH="amd64"; \
      TILT_ARCH="x86_64"; \
      CTLPTL_ARCH="x86_64"; \
      KIND_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      KUBECTL_ARCH="arm64"; \
      HELM_ARCH="arm64"; \
      TILT_ARCH="arm64"; \
      CTLPTL_ARCH="arm64"; \
      KIND_ARCH="arm64"; \
    else \
      echo "Unsupported architecture $ARCH" && exit 1; \
    fi && \
    # Install kubectl (v1.21.12)
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.21.12/bin/linux/${KUBECTL_ARCH}/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    # Install helm (v3.9.1)
    curl -fsSL "https://get.helm.sh/helm-v3.9.1-linux-${HELM_ARCH}.tar.gz" | tar -xzv "linux-${HELM_ARCH}/helm" && \
    mv "linux-${HELM_ARCH}/helm" /usr/local/bin/helm && \
    rm -rf "linux-${HELM_ARCH}" && \
    # Install tilt (v0.33.5)
    curl -fsSL "https://github.com/windmilleng/tilt/releases/download/v0.33.5/tilt.0.33.5.linux.${TILT_ARCH}.tar.gz" | tar -xzv tilt && \
    mv tilt /usr/local/bin/tilt && \
    # Install ctlptl (v0.9.4)
    curl -fsSL "https://github.com/tilt-dev/ctlptl/releases/download/v0.9.4/ctlptl.0.9.4.linux.${CTLPTL_ARCH}.tar.gz" | tar -xzv ctlptl && \
    mv ctlptl /usr/local/bin/ctlptl && \
    # Install kind (v0.11.0)
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-${KIND_ARCH}" && \
    chmod +x ./kind && \
    mv ./kind /usr/local/bin/kind && \
    # Install glooctl
    curl -sL https://run.solo.io/gloo/install | sh && \
    mv /root/.gloo/bin/glooctl /usr/local/bin/glooctl && \
    rm -rf /root/.gloo

# Install Docker CE
RUN curl -fsSL https://get.docker.com | sh \
    && usermod -aG docker vscode

# Install Node.js 18
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.20
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
      GO_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
      GO_ARCH="arm64"; \
    else \
      echo "Unsupported architecture $ARCH" && exit 1; \
    fi && \
    curl -fsSL "https://go.dev/dl/go1.20.linux-${GO_ARCH}.tar.gz" | tar -C /usr/local -xzf - \
    && mkdir -p /home/vscode/go/bin \
    && chown -R vscode:vscode /home/vscode/go

# Configure dynamic path for tidepool bin in vscode shell configs
RUN for shell_rc in /home/vscode/.bashrc /home/vscode/.zshrc; do \
      if [ -f "$shell_rc" ]; then \
        echo 'for dir in /workspaces/tidepool-development*; do if [ -d "$dir/bin" ]; then export PATH="$PATH:$dir/bin"; fi; done' >> "$shell_rc"; \
      fi; \
    done

# Create entrypoint script
RUN cat <<'EOF' > /usr/local/bin/entrypoint.sh
#!/bin/bash
set -e

# 1. Ensure the kube config directory exists
mkdir -p /home/vscode/.kube
chown -R vscode:vscode /home/vscode/.kube

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

# 5. Start Docker daemon
echo "Starting Docker daemon..."
if ! pidof dockerd >/dev/null; then
  sudo service docker start || sudo dockerd &
fi

# 6. Determine Docker gateway IP (typically 172.17.0.1)
sleep 2
DOCKER_IP=$(ip addr show docker0 2>/dev/null | grep -Po 'inet \K[\d.]+' | head -n 1) || true
if [ -z "$DOCKER_IP" ]; then
  DOCKER_IP="172.17.0.1"
fi
echo "Using Docker host gateway IP: $DOCKER_IP"

# 7. Initiate replica set with the Docker gateway IP so Kind containers can connect to it
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

# 8. Pre-configure Tiltconfig.yaml with host IP for MongoDB if it does not exist
for dir in /workspaces/tidepool-development*; do
  if [ -d "$dir" ]; then
    if [ ! -f "$dir/local/Tiltconfig.yaml" ]; then
      echo "Creating $dir/local/Tiltconfig.yaml with MongoDB host configuration..."
      mkdir -p "$dir/local"
      cat <<INNER_EOF > "$dir/local/Tiltconfig.yaml"
mongo:
  secret:
    data_:
      Addresses: "${DOCKER_IP}"
INNER_EOF
      chown -R vscode:vscode "$dir/local"
    else
      echo "$dir/local/Tiltconfig.yaml already exists. Skipping auto-configuration of MongoDB address."
    fi
    break
  fi
done

# Execute the container's main CMD
exec "$@"
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables for the system
ENV KUBECONFIG=/home/vscode/.kube/config
ENV MONGODB_SHELL=/usr/local/bin/mongosh
ENV PATH="/usr/local/go/bin:/home/vscode/go/bin:${PATH}"

USER vscode

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["sleep", "infinity"]
