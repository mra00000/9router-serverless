#!/bin/bash
# ============================================================
# entrypoint.sh — 9router + Google Drive config restore
#
# Required env vars:
#   RCLONE_CONFIG_BASE64  — base64-encoded rclone.conf
#   RCLONE_REMOTE         — remote name in rclone.conf      (e.g. gdrive)
#   RCLONE_REMOTE_PATH    — path on the remote              (e.g. 9router-data)
#
# Optional env vars:
#   PORT                  — 9router port                    (default: 20128)
#
# On startup: downloads db.json + db/ from Drive → local.
# No sync back. Drive is read-only from the container's perspective.
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[9router]${NC} $*"; }
warn()  { echo -e "${YELLOW}[9router]${NC} $*"; }
error() { echo -e "${RED}[9router]${NC} $*" >&2; }
step()  { echo -e "\n${CYAN}[9router]${NC} ── $* ──"; }

# ─────────────────────────────────────────────────────────────
# 1. Validate required env vars
# ─────────────────────────────────────────────────────────────
step "Validating environment"

MISSING=0
for VAR in RCLONE_CONFIG_BASE64 RCLONE_REMOTE RCLONE_REMOTE_PATH; do
  if [[ -z "${!VAR:-}" ]]; then
    error "Missing required env var: $VAR"
    MISSING=1
  fi
done
[[ $MISSING -eq 1 ]] && exit 1

LOCAL_PATH="/root/.9router"
RCLONE_CONFIG_PATH="/tmp/rclone.conf"

REMOTE="${RCLONE_REMOTE}"
REMOTE_PATH="${RCLONE_REMOTE_PATH}"
REMOTE_TARGET="${REMOTE}:${REMOTE_PATH}"

# ─────────────────────────────────────────────────────────────
# 2. Decode rclone config
# ─────────────────────────────────────────────────────────────
step "Decoding rclone config"

echo "${RCLONE_CONFIG_BASE64}" | base64 -d > "${RCLONE_CONFIG_PATH}"
chmod 600 "${RCLONE_CONFIG_PATH}"

if [[ ! -s "${RCLONE_CONFIG_PATH}" ]]; then
  error "Decoded rclone.conf is empty — check your RCLONE_CONFIG_BASE64 value."
  exit 1
fi
if ! grep -q '^\[' "${RCLONE_CONFIG_PATH}"; then
  error "Decoded rclone.conf has no [remote] section — invalid config."
  exit 1
fi

info "Config decoded. Remotes: $(grep '^\[' "${RCLONE_CONFIG_PATH}" | tr -d '[]' | tr '\n' ' ')"

# ─────────────────────────────────────────────────────────────
# 3. Restore: download db.json + db/ from Drive (once, on startup)
# ─────────────────────────────────────────────────────────────
step "Downloading config from Drive"

mkdir -p "${LOCAL_PATH}/db"

rclone copy "${REMOTE_TARGET}/db.json" "${LOCAL_PATH}" \
  --config "${RCLONE_CONFIG_PATH}" \
  --log-level INFO 2>&1 || warn "db.json not found on Drive — skipping."

rclone copy "${REMOTE_TARGET}/db" "${LOCAL_PATH}/db" \
  --config "${RCLONE_CONFIG_PATH}" \
  --log-level INFO 2>&1 || warn "db/ not found on Drive — skipping."

# ─────────────────────────────────────────────────────────────
# 4. Start 9router
# ─────────────────────────────────────────────────────────────
step "Starting 9router"

9router