.PHONY: help build migrate-status migrate-up migrate-down migrate-create clean test docker-build docker-up docker-down docker-shell docker-dev pre-commit-install pre-commit-update pre-commit-run pre-commit-uninstall

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

build: ## Build the migration tool
	@cd migrations && go build -o migrate .
	@echo "✓ Migration tool built"

migrate-status: ## Show migration status
	@./migrate.sh status

migrate-up: ## Apply pending migrations
	@./migrate.sh up

migrate-down: ## Rollback last migration
	@./migrate.sh down

migrate-create: ## Create new migration (usage: make migrate-create NAME=my_migration)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make migrate-create NAME=my_migration"; \
		exit 1; \
	fi
	@./migrate.sh create $(NAME)

init: ## Initialize Terraform
	@cd terraform && terraform init

plan: ## Run terraform plan
	@cd terraform && terraform plan

apply: ## Run terraform apply
	@cd terraform && terraform apply

clean: ## Remove built binaries and temporary files
	@rm -f migrations/migrate

	@rm -f terraform.tfstate.backup_*
	@echo "✓ Cleaned up"

test: build ## Build and test the migration tool
	@./migrate.sh status
	@echo "✓ Migration tool is working"

# Docker targets
docker-build: ## Build Docker images
	@docker compose build

docker-up: ## Start Docker containers
	@docker compose up -d terraform

docker-down: ## Stop Docker containers
	@docker compose down

docker-shell: ## Open shell in Terraform container
	@docker compose run --rm terraform

docker-dev: ## Start development container
	@docker compose up -d terraform-dev
	@docker compose exec terraform-dev

docker-terraform: ## Run terraform command in container (usage: make docker-terraform CMD="plan")
	@docker compose run --rm terraform terraform $(CMD)

docker-migrate: ## Run migration command in container (usage: make docker-migrate CMD="status")
	@docker compose run --rm migrate ./migrate.sh $(CMD)

docker-clean: ## Clean up Docker resources
	@docker compose down -v
	@docker system prune -f

# Pre-commit hooks targets
pre-commit-install: ## Install pre-commit hooks
	@if ! command -v pre-commit >/dev/null 2>&1; then \
		echo "Error: pre-commit is not installed. Install it with: pip install pre-commit"; \
		exit 1; \
	fi
	@pre-commit install
	@pre-commit install --hook-type commit-msg
	@echo "✓ Pre-commit hooks installed"

pre-commit-update: ## Update pre-commit hooks to latest versions
	@pre-commit autoupdate
	@echo "✓ Pre-commit hooks updated"

pre-commit-run: ## Run pre-commit hooks on all files
	@pre-commit run --all-files

pre-commit-uninstall: ## Uninstall pre-commit hooks
	@pre-commit uninstall
	@pre-commit uninstall --hook-type commit-msg
	@echo "✓ Pre-commit hooks uninstalled"

.DEFAULT_GOAL := help
