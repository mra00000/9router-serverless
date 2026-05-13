#!/bin/bash
# ============================================================
# entrypoint.sh — 9router + Google Drive config restore
#
# Required env vars:
#   RCLONE_CONFIG_BASE64  — base64-encoded rclone.conf
#   DB_PATH               — exact rclone path to data.sqlite  (e.g. gdrive:9router-data/db/data.sqlite)
#
# Optional env vars:
#   DATA_DIR              — local base directory              (default: ~/.9router)
#   PORT                  — 9router port                      (default: 20128)
#
# On startup: copies DB_PATH → DATA_DIR/db/data.sqlite (once, read-only from Drive).
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
for VAR in RCLONE_CONFIG_BASE64 DB_PATH; do
  if [[ -z "${!VAR:-}" ]]; then
    error "Missing required env var: $VAR"
    MISSING=1
  fi
done
[[ $MISSING -eq 1 ]] && exit 1

LOCAL_BASE="${DATA_DIR:-$HOME/.9router}"
RCLONE_CONFIG_PATH="/tmp/rclone.conf"

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
# 3. Restore: copy data.sqlite from remote (once, on startup)
# ─────────────────────────────────────────────────────────────
step "Downloading database from remote"

LOCAL_DB="${LOCAL_BASE}/db/data.sqlite"
mkdir -p "${LOCAL_BASE}/db"

rclone copyto "${DB_PATH}" "${LOCAL_DB}" \
  --config "${RCLONE_CONFIG_PATH}" \
  --log-level INFO 2>&1

info "Database copied to ${LOCAL_DB}"

# ─────────────────────────────────────────────────────────────
# 4. Start 9router
# ─────────────────────────────────────────────────────────────
step "Starting 9router"

9router