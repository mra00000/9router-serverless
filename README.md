# 9router — Serverless Deployment

Run **9router** on ephemeral containers (e.g. Render.com) with database persistence via rclone-compatible remote storage (Google Drive, S3, etc.).

On every cold start the container downloads your `data.sqlite` from the remote before starting 9router. The remote is read-only from the container's perspective.

---

## How it works

```
Container starts
      │
      ▼
Decode RCLONE_CONFIG_BASE64 → /tmp/rclone.conf
      │
      ▼
rclone copyto DB_PATH → DATA_DIR/db/data.sqlite
      │
      ▼
9router starts
```

---

## Step 1 — Initialize the database locally

The database needs to exist on the remote before you deploy. Set it up locally first.

**Install 9router:**
```bash
npm install -g 9router
```

**Run it once to generate the database:**
```bash
9router
```

9router creates its data directory at `~/.9router/`. The database file is at:
```
~/.9router/db/data.sqlite
```

Open the dashboard (default `http://localhost:20128`), configure your providers, combos, and any settings you want persisted. Once done, stop 9router.

---

## Step 2 — Configure rclone

Install rclone on your local machine: https://rclone.org/install/

### Google Drive (OAuth — recommended for personal use)

Run the interactive setup:
```bash
rclone config
```

Follow the prompts: choose **n** (new remote) → name it (e.g. `gdrive`) → type **drive** → complete the OAuth flow in your browser.

Verify access:
```bash
rclone ls gdrive:
```

### Google Drive (Service Account — recommended for servers)

Create a Service Account in Google Cloud Console, download the JSON key, and share your target Drive folder with the service account email. Then create the remote manually in `~/.config/rclone/rclone.conf`:

```ini
[gdrive]
type = drive
scope = drive
service_account_file = /path/to/sa-key.json
root_folder_id = YOUR_FOLDER_ID
```

---

## Step 3 — Upload the database to remote storage

Create a folder on your remote and upload the database:

```bash
# Create the folder structure on Drive
rclone mkdir gdrive:9router-data/db

# Upload the database
rclone copyto ~/.9router/db/data.sqlite gdrive:9router-data/db/data.sqlite
```

Verify the upload:
```bash
rclone ls gdrive:9router-data/db
# should show: data.sqlite
```

Note the full rclone path to your file — this becomes your `DB_PATH` env var:
```
gdrive:9router-data/db/data.sqlite
```

---

## Step 4 — Encode the rclone config

The container needs your rclone credentials at runtime via a base64-encoded env var.

```bash
# Linux
base64 -w 0 ~/.config/rclone/rclone.conf

# macO
base64 -i ~/.config/rclone/rclone.conf | tr -d '\n'S
```

Copy the output — this is your `RCLONE_CONFIG_BASE64` value.

---

## Step 5 — Configure environment variables

| Variable | Required | Description |
|---|---|---|
| `RCLONE_CONFIG_BASE64` | Yes | Base64-encoded content of your `rclone.conf` |
| `DB_PATH` | Yes | Full rclone path to `data.sqlite` on the remote (e.g. `gdrive:9router-data/db/data.sqlite`) |
| `DATA_DIR` | No | Local base directory for 9router data (default: `~/.9router`) |
| `PORT` | No | 9router port (default: `20128`) |

---

## Step 6 — Deploy on Render.com

1. Push this repository (with `Dockerfile` and `entrypoint.sh`) to GitHub.
2. Go to **Render → New → Web Service**.
3. Connect your GitHub repo and select **Docker** as the runtime.
4. Set **Port** to `20128`.
5. Under **Environment Variables**, add `RCLONE_CONFIG_BASE64` and `DB_PATH` (and any optional vars).
6. Click **Deploy**.

Render will build the Docker image, start the container, and the entrypoint will pull the database from your remote before launching 9router.

Your service will be available at `https://<your-render-url>` and the OpenAI-compatible API at `https://<your-render-url>/v1`.

---

## Updating the database

The container only reads from the remote on startup — it never writes back. If you change your local 9router config (new providers, combos, etc.) and want to update the remote:

```bash
rclone copyto ~/.9router/db/data.sqlite gdrive:9router-data/db/data.sqlite
```

Then restart (or redeploy) your container so it picks up the new file.

---

## Updating the rclone config

If you refresh OAuth tokens or add a new remote locally, re-encode and update the env var:

```bash
base64 -w 0 ~/.config/rclone/rclone.conf
```

Paste the new value into Render's environment variables dashboard and redeploy.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Missing required env var: RCLONE_CONFIG_BASE64` | Add the env var in Render's dashboard |
| `Missing required env var: DB_PATH` | Add the env var pointing to your remote sqlite file |
| `Decoded rclone.conf has no [remote] section` | Base64 value is corrupt — re-encode and update |
| `rclone copyto` fails | Verify `DB_PATH` is correct with `rclone ls <remote>:<path>` locally |
| Dashboard unreachable | Confirm Render port is `20128` |
