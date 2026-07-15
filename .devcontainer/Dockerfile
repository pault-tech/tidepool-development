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

# Set environment variables for the system
ENV KUBECONFIG=/home/vscode/.kube/config
ENV MONGODB_SHELL=/usr/local/bin/mongosh

USER vscode
