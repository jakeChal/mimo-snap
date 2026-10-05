SHELL := /bin/bash

.PHONY: all help init build install upload smoke-test install-deps init-submodules download-models

# Always run `hf` via pipx to avoid relying on local `hf` installations.
hf := pipx run --spec "huggingface_hub[cli]" hf

SNAP_NAME ?= mimo-v2-6

ENGINE ?= cpu

all: help

#
# Main targets
#

help: ## Show this help message
	@echo "Usage: make <target>"
	@echo
	@echo "Targets:"
	@# List all targets with descriptions (lines starting with '##'):
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-11s %s\n", $$1, $$2}'

init: init-submodules install-deps download-models ## Initialize the build environment (dependencies, model weights, submodules, etc.)

build: ## Build the snap
	./dev/build.sh

install: ## Install the snap
	./dev/install.sh

upload: ## Upload the snap
	./dev/upload.sh

smoke-test: ## Run smoke tests (override with SNAP_NAME=... ENGINE=...)
	sudo ./dev/smoke-test.sh $(SNAP_NAME) $(ENGINE)

#
# Supporting targets
#

install-deps:
	@echo "Installing dependencies..."
	@# Ensure pipx is available for running the hf CLI.
	@command -v pipx >/dev/null 2>&1 || { \
		sudo apt-get update; \
		sudo apt-get install -y pipx; \
	}

init-submodules:
	@echo "Initializing submodules..."
	@if git submodule status | grep -q '^-'; then \
		git submodule update --init; \
	fi

download-models: download-model-9b download-mmproj-9b

# ggml-org/MiMo-V2.6-Distill-Qwen-9B-GGUF Q8_0, split into parts below the 5 GB component limit with:
#   llama-gguf-split --split-max-size 5G MiMo-V2.6-Distill-Qwen-9B-Q8_0.gguf MiMo-V2.6-Distill-Qwen-9B-Q8_0
download-model-9b:
	@echo "Downloading MiMo-V2.6-Distill-Qwen-9B model weights..."
	$(hf) download inference-snaps/mimo-v2-6 MiMo-V2.6-Distill-Qwen-9B-Q8_0-00001-of-00002.gguf \
		--local-dir components/model-9b-q8-0-gguf-1-of-2/
	$(hf) download inference-snaps/mimo-v2-6 MiMo-V2.6-Distill-Qwen-9B-Q8_0-00002-of-00002.gguf \
		--local-dir components/model-9b-q8-0-gguf-2-of-2/

download-mmproj-9b:
	@echo "Downloading MiMo-V2.6-Distill-Qwen-9B mmproj weights..."
	$(hf) download ggml-org/MiMo-V2.6-Distill-Qwen-9B-GGUF mmproj-MiMo-V2.6-Distill-Qwen-9B-Q8_0.gguf \
		--local-dir components/mmproj-9b-q8-0-gguf/
