# 9router on Render.com — Google Drive Persistence

Run **9router** on Render.com's ephemeral containers with full data persistence via Google Drive. Provider tokens, combos, and settings survive every restart.

---

## How it works

```
Container cold-starts
        │
        ▼
Decode RCLONE_CONFIG_BASE64 → /tmp/rclone.conf
        │
        ▼
rclone mount gdrive: → /mnt/gdrive
        │
        ▼
/app/data ──symlink──▶ /mnt/gdrive/9router-data
        │
        ▼
9router --port 20128 --no-browser --skip-update
        │
        ▼
  [running] https://<your-render-url>
            https://<your-render-url>/v1  ← OpenAI-compatible
```

---

## Setup

### Step 1 — Configure rclone locally

Install rclone on your machine and run the interactive setup:

```bash
rclone config
```

Choose **Google Drive**, follow the OAuth flow, and name your remote (e.g. `gdrive`).  
For a **Service Account** instead of OAuth, create the remote manually:

```ini
[gdrive]
type = drive
scope = drive
service_account_file = /path/to/sa-key.json
root_folder_id = YOUR_FOLDER_ID
```

Verify it works:
```bash
rclone ls gdrive:
```

### Step 2 — Encode your rclone config to base64

```bash
# Linux
base64 -w 0 ~/.config/rclone/rclone.conf

# macOS
base64 -i ~/.config/rclone/rclone.conf | tr -d '\n'
```

Copy the output — this is your `RCLONE_CONFIG_BASE64` value.

### Step 3 — Set env vars in Render

| Variable | Required | Description |
|---|---|---|
| `RCLONE_CONFIG_BASE64` | ✅ | Base64-encoded content of your `rclone.conf` |
| `RCLONE_REMOTE` | optional | Remote name in your config (default: `gdrive`) |
| `GDRIVE_MOUNT` | optional | Mount path in container (default: `/mnt/gdrive`) |
| `PORT` | optional | 9router port (default: `20128`) |

### Step 4 — Deploy on Render

1. Push repo (with `Dockerfile` + `entrypoint.sh`) to GitHub
2. **Render → New → Web Service → Docker**
3. Set **Port** to `20128`
4. Set **Health Check Path** to `/`
5. Add env vars → Deploy

---

## Updating your rclone config

If you add a new provider or refresh tokens locally:

```bash
# Re-encode and update the env var in Render
base64 -w 0 ~/.config/rclone/rclone.conf
```

Paste the new value into Render's env var dashboard and redeploy (or just restart the service).

---

## What persists on Drive

Everything in `/app/data` is stored at `9router-data/` inside your Drive folder:

| File | Contents |
|---|---|
| `db.json` | Combos, provider configs, usage stats |
| `tokens/` | OAuth tokens (Claude Code, Codex, Copilot…) |
| `settings.json` | Port, preferences |

Authenticate a provider once → token saved to Drive → automatically restored on every restart.

---

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `RCLONE_CONFIG_BASE64 is not set` | Add the env var in Render dashboard |
| `no [remote] section found` | Base64 value is corrupt — re-encode and update |
| Mount fails after 30s | Wrong remote name, or Drive OAuth token expired — re-run `rclone config` locally and re-encode |
| Data not persisting | Check rclone log in Render's log stream for flush errors |
| Dashboard unreachable | Confirm Render port is `20128` and health check path is `/` |
