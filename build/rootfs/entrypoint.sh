#!/usr/bin/env bash

############################################################
# Copyright (c) 2026 Igor Sadza 
# Released under the GPLv3 license
# ----------------------------------------------------------
# 
# FILE: ./overlay/entrypoint.sh
# DESC: Container initialization entrypoint
#
############################################################

set -Eeuo pipefail

# -----------------------------------
# Load global interactive Bash configuratuin fragments.
# -----------------------------------

BASHRC='/etc/bash.bashrc'
BASHRC_MARKER='# BEGIN bash.bashrc.d loader'


if ! grep -Fq "${BASHRC_MARKER}" "${BASHRC}"; then
    sudo tee -a "${BASHRC}" >/dev/null <<'EOF'

# BEGIN bash.bashrc.d loader
# Load global interactive Bash configuration fragments.
if [[ $- == *i* ]] && [[ -d /etc/bash.bashrc.d ]]; then
    for file in /etc/bash.bashrc.d/*.sh; do
        [[ -r "${file}" ]] && source "${file}"
    done
    unset file
fi
# END bash.bashrc.d loader
EOF
fi

# -----------------------------------
# Execute all container init scripts
# -----------------------------------

function run_init_scripts() {
  local directory=$1
  local prefix=$2
  local script

  [[ -d "${directory}" ]] || return 0

  while IFS= read -r -d '' script; do
    sudo -E bash "${script}"
  done < <(
    find "${directory}" \
      -maxdepth 1 \
      -type f \
      -name "${prefix}" \
      -print0 |
      sort -z
    )
}

run_init_scripts '/etc/cont-init.d/core'
run_init_scripts '/etc/cont-init.d/optional'

# -----------------------------------
# Prepare run/start scripts
# -----------------------------------

function make_executable_scripts() {
  local directory=$1
  local script

  [[ -d "${directory}" ]] || return 0

  while IFS= read -r -d '' script; do
      sudo chmod +x "${script}"
  done < <(
      find ${directory} \
          -maxdepth 1 \
          -type f \
          -name "${prefix}" \
          -print0 |
      sort -z
  )
}

make_executable_scripts '/usr/bin'

# -----------------------------------
# Execute 
# -----------------------------------

# Start 
exec sleep infinity
