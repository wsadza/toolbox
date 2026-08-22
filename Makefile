############################################################
# Copyright (c) 2026 Igor Sadza 
# Released under the GPLv3 license
# ----------------------------------------------------------
#  
# FILE: ./Makefile
# DESC: Building orchestrator
# 
############################################################

############################################################
# Configuration & Metadata
############################################################

# ------------------------
# Shell Flags
# ------------------------
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

# ------------------------
# Files
# ------------------------
COMPOSE_FILE := deployments/docker-compose.yml
CMD_COMPOSE := docker compose -f $(COMPOSE_FILE) 
ACT_FILE := .cicd/github/act.sh

ENV ?= dev
ENV_FILE := .env.$(ENV)

# ------------------------
# Fall back to .env
# ------------------------
ifeq ($(wildcard $(ENV_FILE)),)
ENV_FILE := .env
endif

# ------------------------
# Source environment before every recipe
# ------------------------
define LOAD_ENV
set -a
source "$(ENV_FILE)"
set +a
endef

# ------------------------
# Makefile Default Goal 
# ------------------------
.DEFAULT_GOAL := run

# ------------------------
# Arguments
# ------------------------
ARGS 		 := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
APP_NAME := toolbox

# ------------------------
# Installation
# ------------------------
PREFIX  ?= /usr/local
BINDIR  ?= $(PREFIX)/bin
INSTALL ?= install

############################################################
# Start
# ----------------------------------------------------------
# 	Desc:
# 		- Start application
# 	Usage:
# 		- make start 
# 		- make start ARGS=<args> APP_NAME=<app>
# 	Tips:
# 		- make start ARGS=--progress=plain
#
############################################################

.PHONY: start 
start:
	@echo "------------------------"
	@echo " > Starting $(APP_NAME)..."
	@echo "------------------------"
	@$(LOAD_ENV)
	@$(CMD_COMPOSE) up --build --detach --force-recreate $(ARGS) $(APP_NAME)

############################################################
# Build 
# ----------------------------------------------------------
# 	Desc:
# 		- Run application
# 	Usage:
# 		- make build 
# 		- make run APP_NAME=<app>
# 	Tips:
# 		- make run ARGS=--no-cache
#
############################################################

.PHONY: build
build:
	@$(LOAD_ENV)
	@$(CMD_COMPOSE) build $(ARGS) $(APP_NAME)

############################################################
# Stop 
# ----------------------------------------------------------
# 	Desc:
# 		- Stop application 
# 	Usage:
# 		- make stop
# 		- make stop APP_NAME=<app>
#
############################################################

.PHONY: stop
stop:
	@echo "------------------------"
	@echo " > Stoping $(APP_NAME)..."
	@echo "------------------------"
	@$(LOAD_ENV)
	@$(CMD_COMPOSE) -f deployments/docker-compose.yml stop $(APP_NAME)
	@$(CMD_COMPOSE) -f deployments/docker-compose.yml rm -f $(APP_NAME)

############################################################
# Install 
# ----------------------------------------------------------
# 	Desc: 
# 		- Install `toolbox` into user bin directory
#
# 	Usage:
# 		- make install
#			- sudo make install
#
############################################################

.PHONY: install
install:
	@echo "------------------------"
	@echo " > Install toolbox..."
	@echo "------------------------"
	@$(INSTALL) -d "$(BINDIR)"
	@$(INSTALL) -m 755 toolbox "$(BINDIR)/toolbox"	

############################################################
# CICD 
# ---------------------------------------------------------
# 	Desc:
# 		- Test cicd logic 
# 	Usage:
# 		- make cicd
#
############################################################

.PHONY: cicd 
cicd:
	@echo "------------------------"
	@echo " > Running cicd..."
	@echo "------------------------"
	@$(LOAD_ENV)
	@bash -c $(ACT_FILE)
