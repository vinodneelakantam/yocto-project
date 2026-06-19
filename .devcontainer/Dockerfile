FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

COPY scripts/bootstrap-worker-packages.sh scripts/devcontainer-sanity-check.sh /tmp/scripts/

RUN chmod +x /tmp/scripts/bootstrap-worker-packages.sh /tmp/scripts/devcontainer-sanity-check.sh \
    && /tmp/scripts/bootstrap-worker-packages.sh \
    && rm -rf /tmp/scripts \
    && rm -rf /var/lib/apt/lists/*
