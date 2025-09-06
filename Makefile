# Makefile for Hugo static website
# Variables
PYTHON = python3
VENV_DIR = .venv
VENV_ACTIVATE = $(VENV_DIR)/bin/activate
HUGO_CACHE_DIR = ~/.cache/hugo_cache
PUBLIC_DIR = ./public
RESOURCES_DIR = ./resources
HUGO_LOCK = .hugo_build.lock
REQUIREMENTS = requirements.txt

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show available commands
	@echo "  make all       - Clean, build, format, and run"
	@echo "  make new-post  - Create a new blog post"
	@echo "  make clean     - Clean all (Hugo cache, public, resources, venv)"
	@echo "  make build     - Setup environment and install dependencies"
	@echo "  make run       - Run Hugo server (requires build first)"
	@echo "  make format    - Run pre-commit hooks"

# Standard targets
.PHONY: all
all: clean build format run ## Clean, build, format, and run

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
	@echo "🧹 Cleaning pre-commit..."
	pre-commit gc 2>/dev/null || true
	pre-commit clean 2>/dev/null || true
	@echo "✅ Pre-commit cleanup done."
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
	@echo "📦 Upgrading pip and installing dependencies..."
	@. $(VENV_ACTIVATE) && \
		pip install --upgrade pip && \
		pip install -r $(REQUIREMENTS) && \
		echo "✅ Build complete. Environment is ready." || \
		{ echo "❌ Failed to install dependencies"; exit 1; }


# Run: pre-check environment and start Hugo server
.PHONY: run
run: ## Run Hugo server (requires environment setup)
	@echo "🔍 Checking if environment is ready..."
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "❌ Virtual environment not found. Please run 'make build' first."; \
		exit 1; \
	fi
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then \
		echo "❌ Virtual environment is corrupted. Please run 'make build' first."; \
		exit 1; \
	fi
	@echo "🔍 Checking dependencies..."
	@. $(VENV_ACTIVATE) && python -c "import pre_commit" 2>/dev/null || { \
		echo "❌ Dependencies not installed. Please run 'make build' first."; \
		exit 1; \
	}
	@echo "✅ Environment ready."
	@echo "🚀 Starting full Hugo build..."
	hugo server --disableFastRender

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
