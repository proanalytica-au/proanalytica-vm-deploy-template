# Domain & SSL Setup Guide

This deployment uses **nginx** as a reverse proxy in front of a Docker container, with **Cloudflare** handling DNS, CDN, and SSL termination via Origin Certificates.

## Required Cloudflare Settings

| Setting | Value |
|---|---|
| Proxy status | Enabled (orange cloud) |
| SSL/TLS mode | Full (strict) |
| Always Use HTTPS | Enabled |
| Minimum TLS version | TLS 1.2 |
| HTTP/2 and HTTP/3 | Enabled |
| Automatic HTTPS Rewrites | Enabled |

## Origin Certificate

1. In Cloudflare Dashboard → SSL/TLS → Origin Server → **Create Certificate**
2. Choose **Let Cloudflare generate a private key** (RSA 2048)
3. Set hostname to your domain (e.g. `app.yourdomain.com`)
4. Set validity to 15 years (max)
5. Copy the **Origin Certificate** and **Private Key** into:
   - `./certs/origin.crt`
   - `./certs/origin.key`
6. These files are git-ignored — keep them safe

## Header & Real IP Flow

1. Cloudflare sends `CF-Connecting-IP` header.
2. nginx is configured with `set_real_ip_from` for Cloudflare IP ranges and rewrites the real client IP.
3. nginx forwards standard proxy headers: `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`, `X-Request-Id`.

## Rate Limiting (3 Layers)

| Layer | Location | Config |
|---|---|---|
| Edge | Cloudflare WAF | Bot Fight Mode, Managed Rulesets |
| Proxy | nginx `limit_req` | 120 req/min per IP on `/api/` |
| App | Express/Go middleware | Fixed-window per-endpoint limits |

## Deployment Checklist

- [ ] Cloudflare DNS proxy enabled (orange cloud)
- [ ] Origin cert files exist at `./certs/origin.crt` and `./certs/origin.key`
- [ ] `.env.prod` is filled with correct values
- [ ] `make prod-up` starts without errors
- [ ] `make prod-smoke` passes all checks
- [ ] Real client IP appears in logs (not Docker gateway IP)
- [ ] nginx rate limiting responds 429 on burst
- [ ] SSL labs / test verifies A+ rating