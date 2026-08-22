#!/usr/bin/env bash

############################################################
# Copyright (c) 2026 Igor Sadza
# Released under the GPLv3 license
# ----------------------------------------------------------
#
#   FILE: ./.cicd/github/act.sh
#   DESC: Local CICD Entrypoint
#   TIPS: https://nektosact.com/usage/index.html
#
############################################################

set -euo pipefail

act push \
  --action-offline-mode \
  --secret WORKFLOW_TOKEN="$(gh auth token)" \
  --workflows ${PWD}/.github/workflows/build.yml
