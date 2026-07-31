############################################################
# Copyright (c) 2026 Igor Sadza 
# Released under the GPLv3 license
# ----------------------------------------------------------
#  
# FILE: ./Makefile
# DESC: 
# 
############################################################

############################################################
# Configuration & Metadata
############################################################

# Shell Flags
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# Files
COMPOSE_FILE := deployments/docker-compose.yml
CMD_COMPOSE := docker compose -f $(COMPOSE_FILE) 

ENV ?= dev
ENV_FILE := .env.$(ENV)

# Fall back to .env
ifeq ($(wildcard $(ENV_FILE)),)
ENV_FILE := .env
endif

# Source environment before every recipe
define LOAD_ENV
set -a
source "$(ENV_FILE)"
set +a
endef

# Makefile Default Goal 
.DEFAULT_GOAL := run

# Arguments
ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

############################################################
# Start/Build Target
############################################################

.PHONY: start 
start:
	@echo "------------------------"
	@echo " > Starting toolbox..."
	@echo "------------------------"
	#@$(CMD_COMPOSE) --progress=plain up --build -d toolbox --force-recreate
	@$(CMD_COMPOSE) up --build -d toolbox --force-recreate $(ARGS)

############################################################
# Run Entry Point
# Usage:
#   make run               	# Run the application
#   make run APP_NAME=<app> # Run a specyfic application 
############################################################

.PHONY: run
run:
	@$(LOAD_ENV)
	@$(MAKE) --no-print-directory start 
	@$(MAKE) --no-print-directory install

############################################################
# Stop Entry Point 
# Usage:
#   make stop # Stop the application
############################################################

.PHONY: stop
stop:
	@echo "------------------------"
	@echo " > Stoping toolbox..."
	@echo "------------------------"
	@$(LOAD_ENV)
	@docker-compose -f deployments/docker-compose.yml stop toolbox 
	@docker-compose -f deployments/docker-compose.yml rm -f $(APP_NAME)

############################################################
# Install 
# Usage:
#   make install # Add `toolbox` allias into user .bashrc 
############################################################

.PHONY: install
install:
	@echo "------------------------"
	@echo " > Install toolbox..."
	@echo "------------------------"
	@ALIAS="alias toolbox='docker exec -it -w /host\$${PWD} toolbox /bin/bash'"
	@BASHRC="$${HOME}/.bashrc"
	@grep -Fqx -- "$${ALIAS}" "$${BASHRC}" || echo $${ALIAS} >> $${BASHRC}
