# Makefile for Hugo static website
# Variables
PYTHON = python3
VENV_DIR = .venv
VENV_ACTIVATE = $(VENV_DIR)/bin/activate
VENV_HUGO = $(VENV_DIR)/bin/hugo
HUGO_CACHE_DIR = ~/.cache/hugo_cache
PUBLIC_DIR = ./public
RESOURCES_DIR = ./resources
HUGO_LOCK = .hugo_build.lock
REQUIREMENTS = requirements.txt
HUGO_VERSION := $(shell awk -F '[=\# ]+' '/^hugo==/ { print $2; exit }' $(REQUIREMENTS) | tr -d '\r')

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show available commands
	@echo "  make all       - Clean, build, sync JS, format, and run"
	@echo "  make new-post  - Create a new blog post"
	@echo "  make clean     - Clean all (Hugo cache, public, resources, venv)"
	@echo "  make build     - Setup environment and install dependencies"
	@echo "  make sync-js   - Copy scripts/gtag.js to assets/js/custom.js"
	@echo "  make run       - Run Hugo server (requires build first)"
	@echo "  make format    - Run pre-commit hooks"
	@echo "  make gitleaks  - Scan full git history for secrets (uses baseline)"

# Standard targets
.PHONY: all
all: clean build sync-js format gitleaks run

# Create new blog post
.PHONY: new-post
new-post: ## Create a new blog post (interactive)
	@echo "📝 Creating new blog post..."
	@./scripts/new-post.sh

# Clean everything (equivalent to clean.sh)
.PHONY: clean
clean: ## Clean all Hugo artifacts, cache, and virtual environment
	@echo "🧹 Cleaning Hugo build artifacts..."
	rm -rf $(HUGO_CACHE_DIR)
	rm -rf $(PUBLIC_DIR)
	rm -rf $(RESOURCES_DIR)
	rm -rf $(HUGO_LOCK)
	@echo "✅ Hugo cleanup done."
	@echo "🧹 Cleaning virtual environment..."
	@if [ -d "$(VENV_DIR)" ]; then \
		rm -rf $(VENV_DIR); \
		echo "✅ Virtual environment removed."; \
	else \
		echo "No virtual environment found."; \
	fi
	@echo "✅ Full cleanup complete."

# Build: setup venv and install dependencies (equivalent to build-local.sh setup part)
.PHONY: build
build: ## Setup virtual environment and install dependencies
	@echo "🐍 Checking Python installation..."
	@if ! command -v $(PYTHON) > /dev/null 2>&1; then \
		echo "❌ Error: $(PYTHON) is not installed. Please install Python 3.x"; \
		exit 1; \
	fi
	@echo "🐍 Creating Python virtual environment..."
	@$(PYTHON) -m venv $(VENV_DIR) || { echo "❌ Failed to create virtual environment"; exit 1; }
	@echo "✅ Virtual environment created successfully."
	@if [ -z "$(HUGO_VERSION)" ]; then \
		echo "❌ Pin Hugo in $(REQUIREMENTS) as hugo==<version> (used by local install and CI)."; \
		exit 1; \
	fi
	@echo "📦 Upgrading pip and installing dependencies (Hugo $(HUGO_VERSION))..."
	@. $(VENV_ACTIVATE) && \
		if command -v uv > /dev/null 2>&1; then \
			uv pip install --upgrade pip && \
			uv pip install -r $(REQUIREMENTS); \
		else \
			python -m pip install --upgrade pip && \
			python -m pip install -r $(REQUIREMENTS); \
		fi && \
		echo "✅ Build complete. Environment is ready." || \
		{ echo "❌ Failed to install dependencies"; exit 1; }

# Sync custom JavaScript from source before running Hugo
.PHONY: sync-js
sync-js: ## Copy scripts/gtag.js to assets/js/custom.js
	@echo "🔄 Syncing scripts/gtag.js to assets/js/custom.js..."
	@if [ ! -f "./scripts/gtag.js" ]; then \
		echo "❌ Source file scripts/gtag.js not found."; \
		exit 1; \
	fi
	@mkdir -p ./assets/js
	@cp ./scripts/gtag.js ./assets/js/custom.js
	@echo "✅ JavaScript sync complete."

# Run: pre-check environment and start Hugo server
.PHONY: run
run: sync-js ## Run Hugo server (requires environment setup)
	@echo "🔍 Checking if environment is ready..."
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "❌ Virtual environment not found. Please run 'make build' first."; \
		exit 1; \
	fi
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then \
		echo "❌ Virtual environment is corrupted. Please run 'make build' first."; \
		exit 1; \
	fi
	@if [ ! -x "$(VENV_HUGO)" ]; then \
		echo "❌ Hugo binary not found in virtual environment. Please run 'make build' first."; \
		exit 1; \
	fi
	@echo "🔍 Checking dependencies..."
	@. $(VENV_ACTIVATE) && python -c "import pre_commit" 2>/dev/null || { \
		echo "❌ Dependencies not installed. Please run 'make build' first."; \
		exit 1; \
	}
	@echo "✅ Environment ready."
	@echo "🚀 Starting full Hugo build..."
	@$(VENV_HUGO) server --disableFastRender --environment production --gc --cleanDestinationDir

# Format: install and run pre-commit hooks
.PHONY: format
format: ## Run pre-commit hooks (install if needed)
	@echo "🔍 Checking if environment is ready..."
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "❌ Virtual environment not found. Please run 'make build' first."; \
		exit 1; \
	fi
	@echo "🔧 Installing/updating pre-commit hooks..."
	@. $(VENV_ACTIVATE) && pre-commit install 2>/dev/null || true
	@echo "🚀 Running pre-commit hooks on all files..."
	@. $(VENV_ACTIVATE) && pre-commit run --all-files --verbose
	@echo "✅ Pre-commit formatting complete."

# Gitleaks: scan full git history for leaked secrets.
# Uses .gitleaks.toml for rules/allowlists and .gitleaks-baseline.json to
# suppress already-known historical findings (e.g. public publishable keys).
GITLEAKS_CONFIG = .gitleaks.toml
GITLEAKS_BASELINE = .gitleaks-baseline.json

.PHONY: gitleaks
gitleaks: ## Scan full git history for secrets (uses baseline)
	@echo "🔍 Checking if environment is ready..."
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "❌ Virtual environment not found. Please run 'make build' first."; \
		exit 1; \
	fi
	@if ! bash -c 'source $(VENV_ACTIVATE) && command -v gitleaks > /dev/null 2>&1'; then \
		echo "❌ gitleaks not found in venv. Please run 'make build' first."; \
		exit 1; \
	fi
	@echo "🛡️  Running gitleaks full-history scan..."
	@. $(VENV_ACTIVATE) && gitleaks git --redact --verbose \
		--config=$(GITLEAKS_CONFIG) \
		--baseline-path=$(GITLEAKS_BASELINE) \
		|| { echo "❌ gitleaks found new leaks (not in baseline). Rotate the secret and re-run."; exit 1; }
	@echo "✅ gitleaks scan passed: no new leaks found."

.PHONY: gitleaks-baseline
gitleaks-baseline: ## Regenerate the gitleaks baseline (run after rotating/removing known leaks)
	@echo "🔄 Regenerating gitleaks baseline..."
	@. $(VENV_ACTIVATE) && gitleaks git --redact \
		--config=$(GITLEAKS_CONFIG) \
		--report-format json \
		--report-path $(GITLEAKS_BASELINE)
	@echo "✅ Baseline written to $(GITLEAKS_BASELINE). Commit it to suppress these findings."
