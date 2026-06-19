FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

COPY scripts/bootstrap-worker-packages.sh /tmp/bootstrap-worker-packages.sh

RUN chmod +x /tmp/bootstrap-worker-packages.sh \
    && /tmp/bootstrap-worker-packages.sh \
    && rm -f /tmp/bootstrap-worker-packages.sh \
    && rm -rf /var/lib/apt/lists/*

hostRequirements:
  storage: 64gb
