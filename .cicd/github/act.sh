#!/bin/bash
# https://nektosact.com/usage/index.html

# ----
#cat << EOF > /tmp/act_secrets
#GITHUB_TOKEN=""
#TOKEN=""
#SEMANTIC_RELEASE_TOKEN=""
#EOF
# ----

act push \
  --action-offline-mode \
  --secret WORKFLOW_TOKEN="$(gh auth token)" \
  --workflows ${PWD}/.github/workflows/build.yml
#  --eventpath ${PWD}/.github/events/push-master.json \
#  --secret-file /tmp/act_secrets
