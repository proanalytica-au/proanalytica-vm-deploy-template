SHELL := /bin/bash
.DEFAULT_GOAL := help

COMPOSE = docker compose -f docker-compose.prod.yml
PORT ?= 3000

.PHONY: help

help: ## Show available make targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nAvailable targets:\n\n"} /^[a-zA-Z0-9_.-]+:.*##/ {printf "  %-24s %s\n", $$1, $$2}' Makefile
	@printf "\n"

# ── Production ─────────────────────────────────────

prod-config: ## Show resolved production compose services
	$(COMPOSE) config --services

prod-build: ## Build production container
	$(COMPOSE) build app

prod-up: ## Start production stack
	$(COMPOSE) up -d --build --remove-orphans

prod-down: ## Stop production stack
	$(COMPOSE) down

prod-ps: ## List production containers
	$(COMPOSE) ps

prod-logs: ## Tail production logs
	$(COMPOSE) logs --tail=150 app proxy

prod-smoke: ## Run smoke test against production proxy
	@set -euo pipefail; \
	curl -kfsS "https://localhost/" >/dev/null; \
	echo "Main page OK"; \
	curl -kfsS "https://localhost/health" >/dev/null; \
	echo "Health OK"; \
	echo "Smoke test passed"

# ── Local ──────────────────────────────────────────

local-build: ## Build local container
	docker compose build app

local-up: ## Start local stack
	docker compose up -d --build --remove-orphans

local-down: ## Stop local stack
	docker compose down

local-logs: ## Tail local logs
	docker compose logs --tail=150 app

local-smoke: ## Run smoke test against local
	@set -euo pipefail; \
	curl -fsS "http://localhost:$(PORT)/" >/dev/null; \
	echo "Main page OK"; \
	curl -fsS "http://localhost:$(PORT)/health" >/dev/null; \
	echo "Health OK"; \
	echo "Smoke test passed"

# ── Cleanup ────────────────────────────────────────

stop: ## Stop all stacks
	-$(COMPOSE) down --remove-orphans 2>/dev/null || true
	-docker compose down --remove-orphans 2>/dev/null || true
	@echo "All stacks stopped."

clean: ## Stop all stacks and prune dangling images
	$(MAKE) stop
	-docker image prune -f 2>/dev/null || true
	@echo "Clean complete."