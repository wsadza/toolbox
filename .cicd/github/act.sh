#!/bin/bash
# https://nektosact.com/usage/index.html

# ----
#cat << EOF > /tmp/act_secrets
#GITHUB_TOKEN=""
#TOKEN=""
#EOF
# ----

act push \
  --secret GITHUB_TOKEN="$(gh auth token)" \
  --workflows ${PWD}/.github/workflows/release.yml \
  --eventpath ${PWD}/.github/events/push-master.json \
  --secret-file /tmp/act_secrets
