#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

cd "$ROOT_DIR"

echo "Starting production deployment..."

echo "Recreating services..."
docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans

echo "Waiting for health checks..."
for _ in $(seq 1 20); do
  if curl -kfsS "https://localhost/" >/dev/null; then
    echo "Health check passed"
    break
  fi
  sleep 3
done

if ! curl -kfsS "https://localhost/" >/dev/null; then
  echo "Health check failed"
  docker compose -f "$COMPOSE_FILE" ps
  docker compose -f "$COMPOSE_FILE" logs --tail=200
  exit 1
fi

echo "Deployment completed successfully"