# ============================================================
# Dockerfile — 9router + Google Drive persistence via rclone sync
# Target: Render.com (ephemeral, no persistent disk, no FUSE)
# Auth:   RCLONE_CONFIG_BASE64 env var (base64-encoded rclone.conf)
# Port:   20128 (9router default)
# ============================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=20
ENV PORT=20128

WORKDIR /app

# ─────────────────────────────────────────────────────────────
# 1. System packages (no fuse3 needed)
# ─────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────
# 2. Node.js
# ─────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ─────────────────────────────────────────────────────────────
# 3. rclone
# ─────────────────────────────────────────────────────────────
RUN curl -fsSL https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip \
    && unzip /tmp/rclone.zip -d /tmp/rclone-dist \
    && mv /tmp/rclone-dist/rclone-*-linux-amd64/rclone /usr/local/bin/rclone \
    && chmod 755 /usr/local/bin/rclone \
    && rm -rf /tmp/rclone.zip /tmp/rclone-dist

# ─────────────────────────────────────────────────────────────
# 4. Install 9router globally
# ─────────────────────────────────────────────────────────────
RUN npm install -g 9router

# ─────────────────────────────────────────────────────────────
# 5. Entrypoint
# ─────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 20128

ENTRYPOINT ["/entrypoint.sh"]