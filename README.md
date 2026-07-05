# Proanalytica VM Deploy Template

A reusable **Docker Compose + nginx + Cloudflare** deployment template for Proanalytica web apps on a single VM.

**Why this template?** Many of our apps (Next.js, Express, static sites, API backends) don't need Kubernetes or complex orchestration — they just need a solid, repeatable Docker deployment behind an nginx reverse proxy. This template captures what we've learned from PristinePro, ESL Dispatch Board, and other production deployments.

## How to Use This Template

### Option A: Use as a GitHub Template (recommended)

The repo is configured as a [GitHub template repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template).

1. Go to https://github.com/proanalytica-au/proanalytica-vm-deploy-template
2. Click the green **"Use this template"** button → **"Create a new repository"**
3. Set **Owner** to `proanalytica-au`
4. Name your repo (e.g. `my-new-app`)
5. Click **Create repository**

```bash
# Clone your new repo
git clone https://github.com/proanalytica-au/my-new-app.git
cd my-new-app
```

### Option B: Clone and Push to a New Repo

```bash
# Clone the template
git clone https://github.com/proanalytica-au/proanalytica-vm-deploy-template.git my-new-app
cd my-new-app

# Create a new empty repo in the proanalytica-au org
gh repo create proanalytica-au/my-new-app --public --description "Short description"

# Push the template to the new repo
git remote set-url origin https://github.com/proanalytica-au/my-new-app.git
git push -u origin main
```

### Option C: Copy Files into an Existing Project

```bash
# Clone template to a temp location
git clone --depth=1 https://github.com/proanalytica-au/proanalytica-vm-deploy-template.git /tmp/deploy-tmp

# Copy the deployment files into your existing project
cp -r /tmp/deploy-tmp/.github /tmp/deploy-tmp/Dockerfile \
  /tmp/deploy-tmp/Makefile /tmp/deploy-tmp/docker-compose*.yml \
  /tmp/deploy-tmp/nginx* /tmp/deploy-tmp/deploy-production.sh \
  /tmp/deploy-tmp/domain-setup-guide.md /tmp/deploy-tmp/.env.example \
  /tmp/deploy-tmp/.gitignore \
  /path/to/your/project/
```

## Setup Checklist

### 1. Replace `{{APP_NAME}}` placeholders

The `docker-compose.yml` and `docker-compose.prod.yml` files contain `{{APP_NAME}}` placeholders used for container names and volume names. Replace them globally:

```bash
# In each file, replace {{APP_NAME}} with your app's name (lowercase, hyphens)
# e.g. sed -i 's/{{APP_NAME}}/my-new-app/g' docker-compose.yml docker-compose.prod.yml
```

### 2. Customize the Dockerfile

Edit `Dockerfile` for your specific app framework:

| App type | Build tool | Runtime | CMD |
|---|---|---|---|
| Next.js | `next build` (with `output: "standalone"`) | `node:20-alpine` | `node server.js` |
| Express / Node API | `esbuild` or `tsc` | `node:20-alpine` | `node dist/index.js` |
| Vite / CRA SPA | `vite build` | `nginx:alpine` (static serve) | nginx |
| Go API | `go build` | `scratch` or `gcr.io/distroless/base` | binary |
| Python / FastAPI | `pip` | `python:3.12-slim` | `uvicorn` |

See the comments in `Dockerfile` for framework-specific alternatives.

### 3. Set up environment

```bash
cp .env.example .env.prod
# Edit .env.prod with your actual values
```

### 4. Add Cloudflare Origin Certificate

```bash
mkdir -p certs
# Place certificate and key in ./certs/
# See domain-setup-guide.md for Cloudflare instructions
```

### 5. Configure GitHub Secrets and Variables

In your repo **Settings → Secrets and variables → Actions**:

| Type | Key | Description |
|---|---|---|
| Secret | `SERVICEM8_API_KEY` | App-specific API keys |
| Secret | `SENDGRID_API_KEY` | Email service keys |
| Variable | `PROXY_HTTPS_PORT` | Default: `443` |
| Variable | `SSL_CERT_PATH` | Default: `./certs/origin.crt` |
| Variable | `SSL_KEY_PATH` | Default: `./certs/origin.key` |

Then update `.github/workflows/deploy.yml` with your app's secret/variable names.

### 6. Set up the VM

Requirements on the target VM:
- Docker Engine + Docker Compose plugin
- GitHub self-hosted runner registered with labels `[self-hosted, prod]` (or `[self-hosted, dev]` for staging)
- Cloudflare Origin Certificate at `./certs/origin.crt` and `./certs/origin.key`
- Update `deploy.yml` `working-directory` path to match where the runner stores the repo

### 7. Deploy

```bash
# Build and start
make prod-up

# Verify everything is running
make prod-smoke

# Check logs
make prod-logs
```

## Architecture

```
Internet → Cloudflare (CDN/WAF/SSL) → VM port 443
                                         │
                                    nginx (reverse proxy)
                                      ├── /api/* → app:3000
                                      ├── /ws/*  → app:3000 (WebSocket)
                                      └── /*      → app:3000
```

- **Cloudflare**: DNS, CDN, SSL termination (Origin Certificate), WAF, bot protection
- **nginx**: Rate limiting, real-IP from Cloudflare, security headers, static caching
- **Docker Compose**: App container + optional Postgres/Redis behind internal network
- **Self-hosted runner**: GitHub Actions runner on the VM for auto-deploy

## CI/CD

Two environments via GitHub Actions:

| Branch | Environment | Runner | Compose file | SSL |
|---|---|---|---|---|
| `staging` | dev | `self-hosted, dev` | `docker-compose.yml` | No |
| `main` | prod | `self-hosted, prod` | `docker-compose.prod.yml` | Yes |

## What's Included

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build template (customize for your app) |
| `docker-compose.yml` | Local dev compose (app + optional services) |
| `docker-compose.prod.yml` | Production compose (app + nginx proxy + optional DB) |
| `nginx.conf` | Cloudflare-aware nginx config (real-IP, rate limiting, Gzip, security headers) |
| `nginx-prod-proxy.conf` | Production nginx virtual host (SSL, proxy pass, rate limits, WebSocket) |
| `Makefile` | Standard targets: `prod-up`, `prod-down`, `prod-smoke`, `local-up`, etc. |
| `.github/workflows/deploy.yml` | GitHub Actions CI/CD for self-hosted runners (staging + prod) |
| `deploy-production.sh` | Manual deploy script with health check loop |
| `domain-setup-guide.md` | Cloudflare + Origin Certificate + SSL setup |
| `.env.example` | All environment variables documented |

## Directory Structure

```
project/
├── Dockerfile                  # App build (customize per framework)
├── docker-compose.yml          # Local dev
├── docker-compose.prod.yml     # Production
├── nginx.conf                  # Base nginx config (Cloudflare, rate limits, gzip)
├── nginx-prod-proxy.conf       # Prod virtual host (SSL, proxy rules, WebSocket)
├── Makefile                    # Make targets
├── deploy-production.sh        # Manual deploy script
├── domain-setup-guide.md       # Cloudflare/SSL guide
├── .env.example                # Documented env vars
├── .env.prod                   # (git-ignored) actual production secrets
├── certs/
│   ├── origin.crt              # (git-ignored) Cloudflare Origin Cert
│   └── origin.key              # (git-ignored) Cloudflare Origin Key
└── .github/workflows/deploy.yml
```

## Pitfalls

- **`{{APP_NAME}}` placeholders**: Search and replace these in `docker-compose.yml` and `docker-compose.prod.yml` before first use.
- **Next.js requires `output: "standalone"`**: Add `output: "standalone"` to `next.config.ts` or the Docker build won't have bundled dependencies.
- **Self-hosted runner path**: The `deploy.yml` uses `working-directory` referencing `/home/deploy/{{APP_NAME}}` — change this to the actual checkout path on your VM.
- **Cloudflare proxy**: If the orange cloud is off, traffic bypasses Cloudflare SSL and hits nginx directly. nginx expects SSL on 443 and will refuse the connection.
- **Rate limits**: Default nginx `limit_req` is 120 req/min per IP on `/api/`. Adjust for your app's traffic patterns.
- **First deploy**: The app container must expose a `/health` endpoint or the nginx healthcheck will fail. If your app uses a different healthcheck path, update both the `Dockerfile` HEALTHCHECK and `nginx-prod-proxy.conf`.