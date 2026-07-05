# Proanalytica VM Deploy Template

A reusable **Docker Compose + nginx + Cloudflare** deployment template for Proanalytica web apps on a single VM.

**Why this template?** Many of our apps (Next.js, Express, static sites, API backends) don't need Kubernetes or complex orchestration — they just need a solid, repeatable Docker deployment behind an nginx reverse proxy. This template captures what we've learned from PristinePro, ESL Dispatch Board, and other production deployments.

## What's Included

| File | Purpose |
|---|---|
| `Dockerfile` | Multi-stage build template (customize for your app) |
| `docker-compose.yml` | Local dev compose (app + optional services) |
| `docker-compose.prod.yml` | Production compose (app + nginx proxy + optional DB) |
| `nginx.conf` | Cloudflare-aware nginx config (real-IP, rate limiting, Gzip, security headers) |
| `nginx-prod-proxy.conf` | Production nginx virtual host (SSL, proxy pass, rate limits) |
| `Makefile` | Standard targets: `prod-up`, `prod-down`, `prod-smoke`, `local-up`, etc. |
| `.github/workflows/deploy.yml` | GitHub Actions CI/CD for self-hosted runners (staging + prod) |
| `deploy-production.sh` | Manual deploy script (health checks + rollback awareness) |
| `domain-setup-guide.md` | Cloudflare + Origin Certificate + SSL setup |
| `.env.example` | All environment variables documented |

## Quick Start

```bash
# Clone this template into your project
# Copy and customize for your app

# 1. Set up environment
cp .env.example .env.prod

# 2. Place Cloudflare Origin Certificate in ./certs/
#    (see domain-setup-guide.md)

# 3. Deploy
make prod-up

# 4. Verify
make prod-smoke
```

## Architecture

```
Internet → Cloudflare (CDN/WAF/SSL) → VM port 443
                                         │
                                    nginx (reverse proxy)
                                      ├── /api/* → app:3000
                                      └── /*      → app:3000
```

- **Cloudflare**: DNS, CDN, SSL termination (Origin Certificate), WAF, bot protection
- **nginx**: Rate limiting, real-IP from Cloudflare, security headers, static caching
- **Docker Compose**: App container + optional Postgres/Redis behind internal network
- **Self-hosted runner**: GitHub Actions runner on the VM for auto-deploy

## CI/CD

Two environments via GitHub Actions:

| Branch | Environment | Runner | Config |
|---|---|---|---|
| `staging` | dev | `self-hosted, dev` | `docker-compose.yml` (no SSL) |
| `main` | prod | `self-hosted, prod` | `docker-compose.prod.yml` (SSL) |

Set up secrets/vars in your GitHub repo settings matching the `.env.example` keys.

## Customization Checklist

1. **Dockerfile**: Adjust build steps for your framework (Next.js, Express, Vite, etc.)
2. **docker-compose.yml**: Add/remove services (Postgres, Redis, etc.)
3. **docker-compose.prod.yml**: Update container names, ports, resource limits
4. **nginx-prod-proxy.conf**: Adjust proxy pass ports, rate limit zones
5. **Makefile**: Update `PORT` default, add custom targets
6. **deploy.yml**: Update working-directory path for self-hosted runner
7. **Domain**: Update `domain-setup-guide.md` with your actual hostname

## Directory Structure

```
project/
├── Dockerfile                  # App build (customize per framework)
├── docker-compose.yml          # Local dev
├── docker-compose.prod.yml     # Production
├── nginx.conf                  # Base nginx config (Cloudflare, rate limits, gzip)
├── nginx-prod-proxy.conf       # Prod virtual host (SSL, proxy rules)
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