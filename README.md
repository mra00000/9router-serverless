# 9router — Serverless Deployment

Run **9router** on Render.com using its [Secret Files](https://docs.render.com/secret-files) feature to supply the database.

---

## Deploy

### 1 — Run 9router locally

```bash
docker run -it --rm -v ${PWD}:/root/.9router/db -p 20128:20128 mra00000/9router
```

Open the dashboard at `http://localhost:20128`, configure your providers and combos, then stop 9router.

The database is at:
```
<current directory>/data.sqlite
```

### 2 — Upload the database to Render

In your Render service, go to **Environment → Secret Files** and upload `data.sqlite` to it, uploaded secret files will available in container under path ```/etc/secrets```

### 3 — Build and deploy

Connect this repo to Render as a **Docker** web service, or directly deploy from docker hub at `mra00000/9router` and deploy.

No environment variables needed.

---

## Updating the database

Re-run 9router locally, make your changes, then re-upload `~/.9router/db/data.sqlite` to Render's Secret Files and redeploy.
