# ──────────────────────────────────────────────
# Dockerfile Template — Customize for your app
# ──────────────────────────────────────────────
# Uncomment the section for your app type:
#
#   Next.js (standalone) — lines 35-40, 53
#   Express / Node API   — lines 43-46, 55
#   Vite / CRA SPA       — lines 48-51, 56
#   Go API               — lines 49, 57
#   Python / FastAPI     — lines 49, 58

# ==== BUILDER STAGE (adjust for your framework) ====
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --include=optional; else npm install --include=optional; fi

# Copy source
COPY tsconfig.json ./
COPY src ./src
COPY public ./public

# Build
RUN npm run build

# ==== RUNTIME STAGE ====
FROM node:20-alpine AS runtime

WORKDIR /app

# Health check dependency
RUN apk add --no-cache curl && \
  chown node:node /app

USER node

# ── Next.js (standalone) ──────────────────────
# COPY --from=builder --chown=node:node /app/.next/standalone ./
# COPY --from=builder --chown=node:node /app/.next/static ./.next/static
# COPY --from=builder --chown=node:node /app/public ./public

# ── Express / Node API ────────────────────────
# COPY --from=builder --chown=node:node /app/dist ./dist
# COPY --chown=node:node package.json ./

# ── Vite SPA / Static site (nginx runtime) ────
# FROM nginx:alpine AS runtime
# COPY --from=builder /app/dist /usr/share/nginx/html

# ── Go binary ─────────────────────────────────
# FROM gcr.io/distroless/base-debian12 AS runtime
# COPY --from=builder /app/bin/server /server

# ── Python / FastAPI ──────────────────────────
# FROM python:3.12-slim AS runtime
# COPY --from=builder /app /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || curl -f http://localhost:3000/ || exit 1

# Uncomment the right CMD for your app:
# CMD ["node", "server.js"]         # Next.js (standalone)
# CMD ["node", "dist/index.js"]     # Express / Node API
# CMD nginx -g "daemon off;"        # Vite SPA / Static
# CMD ["./server"]                  # Go
# CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3000"]  # FastAPI