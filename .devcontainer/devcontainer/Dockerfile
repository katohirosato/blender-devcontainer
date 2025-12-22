FROM mcr.microsoft.com/devcontainers/base:ubuntu
LABEL org.opencontainers.image.source="https://github.com/peakys-org/blender-devcontainer/"
RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-openbsd \
    libxxf86vm1 \
    libxfixes3 \
    libxi6 \
    libxkbcommon0 \
    libsm6 \
    libgl1 \
    libxrender1\
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /workspaces/
ENTRYPOINT ["sh", "-c", "tail -f --retry /workspaces/development/output*.log 2>/dev/null"]