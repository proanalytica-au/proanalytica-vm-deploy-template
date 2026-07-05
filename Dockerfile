# ──────────────────────────────────────────────
# Dockerfile Template — Customize for your app
# ──────────────────────────────────────────────
# Examples:
#   Next.js:  output: "standalone" + Node.js runtime
#   Express:  esbuild + node dist/index.js
#   Vite SPA: nginx static serving
#   API:      Go build + scratch/alpine runtime

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

# Copy built artifacts from builder
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static
COPY --from=builder --chown=node:node /app/public ./public

# or for Express:
# COPY --from=builder --chown=node:node /app/dist ./dist
# COPY --chown=node:node package.json ./

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || curl -f http://localhost:3000/ || exit 1

# For Next.js standalone:
CMD ["node", "server.js"]
# For Express:
# CMD ["node", "dist/index.js"]