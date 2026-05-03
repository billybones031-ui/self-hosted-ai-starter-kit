.DEFAULT_GOAL := help

.PHONY: help install \
        up-cpu up-gpu-nvidia up-gpu-amd up-mac \
        down-cpu down-gpu-nvidia down-gpu-amd down-mac \
        pull-cpu pull-gpu-nvidia pull-gpu-amd pull-mac \
        upgrade-cpu upgrade-gpu-nvidia upgrade-gpu-amd upgrade-mac

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# ── Setup ─────────────────────────────────────────────────────────────────────

install: ## Copy .env.example to .env (skips if .env already exists)
	@[ -f .env ] && echo ".env already exists, skipping." || (cp .env.example .env && echo "Created .env from .env.example")

# ── Start ─────────────────────────────────────────────────────────────────────

up-cpu: ## Start stack with CPU-only Ollama
	docker compose --profile cpu up

up-gpu-nvidia: ## Start stack with Nvidia GPU Ollama
	docker compose --profile gpu-nvidia up

up-gpu-amd: ## Start stack with AMD GPU Ollama (Linux / ROCm)
	docker compose --profile gpu-amd up

up-mac: ## Start stack for Mac / Apple Silicon (Ollama runs on host)
	docker compose up

# ── Stop ──────────────────────────────────────────────────────────────────────

down-cpu: ## Stop and remove CPU stack containers
	docker compose --profile cpu down

down-gpu-nvidia: ## Stop and remove Nvidia GPU stack containers
	docker compose --profile gpu-nvidia down

down-gpu-amd: ## Stop and remove AMD GPU stack containers
	docker compose --profile gpu-amd down

down-mac: ## Stop and remove Mac stack containers
	docker compose down

# ── Pull images only ──────────────────────────────────────────────────────────

pull-cpu: ## Pull latest images for CPU profile
	docker compose --profile cpu pull

pull-gpu-nvidia: ## Pull latest images for Nvidia GPU profile
	docker compose --profile gpu-nvidia pull

pull-gpu-amd: ## Pull latest images for AMD GPU profile
	docker compose --profile gpu-amd pull

pull-mac: ## Pull latest images for Mac profile
	docker compose pull

# ── Upgrade (pull + recreate + up) ───────────────────────────────────────────

upgrade-cpu: ## Pull latest images and restart CPU stack
	docker compose --profile cpu pull
	docker compose create && docker compose --profile cpu up

upgrade-gpu-nvidia: ## Pull latest images and restart Nvidia GPU stack
	docker compose --profile gpu-nvidia pull
	docker compose create && docker compose --profile gpu-nvidia up

upgrade-gpu-amd: ## Pull latest images and restart AMD GPU stack
	docker compose --profile gpu-amd pull
	docker compose create && docker compose --profile gpu-amd up

upgrade-mac: ## Pull latest images and restart Mac stack
	docker compose pull
	docker compose create && docker compose up
