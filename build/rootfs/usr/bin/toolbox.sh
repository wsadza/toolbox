#!/usr/bin/env bash

############################################################
# Copyright (c) 2026 Igor Sadza
# Released under the GPLv3 license
# ----------------------------------------------------------
#
# FILE: ./usr/bin/toolbox.sh
# DESC: Container main executable 
#
############################################################

set -Eeuo pipefail

: "${TOOLBOX_UID:?}"
: "${TOOLBOX_GID:?}"
: "${TOOLBOX_GROUPS:?}"
: "${TOOLBOX_USER:?}"
: "${TOOLBOX_HOME:?}"
: "${TOOLBOX_CWD:?}"
: "${TOOLBOX_RUNTIME_ROOT:?}"
: "${TOOLBOX_SHARED_GID:?}"

# ===================================
# Runtime directory
# ===================================

runtime_dir="${TOOLBOX_RUNTIME_ROOT}/${TOOLBOX_UID}"

install \
    -d \
    -o "${TOOLBOX_UID}" \
    -g "${TOOLBOX_GID}" \
    -m 0700 \
    "${runtime_dir}"

install \
    -d \
    -o "${TOOLBOX_UID}" \
    -g "${TOOLBOX_GID}" \
    -m 0700 \
    "${runtime_dir}/go"

# ===================================
# Session environment
# ===================================

export HOME="${TOOLBOX_HOME}"
export USER="${TOOLBOX_USER}"
export LOGNAME="${TOOLBOX_USER}"

export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

export XDG_RUNTIME_DIR="${runtime_dir}"

export GOTMPDIR="${runtime_dir}/go"

# ===================================
# Working directory
# ===================================

cd "${TOOLBOX_CWD}"

# ===================================
# Supplementary groups
# ===================================

getent group "${TOOLBOX_GID}" >/dev/null ||
    groupadd --gid "${TOOLBOX_GID}" "${TOOLBOX_USER}"

getent passwd "${TOOLBOX_UID}" >/dev/null ||
    useradd \
        --uid "${TOOLBOX_UID}" \
        --gid "${TOOLBOX_GID}" \
        --home-dir "${TOOLBOX_HOME}" \
        --shell /bin/bash \
        --no-create-home \
        "${TOOLBOX_USER}"

# ===================================
# Supplementary groups
# ===================================

SUDO_GID="$(getent group sudo | awk -F: 'NR == 1 { print $3 }')"
test -n "${SUDO_GID}"

session_groups="$(
    printf '%s\n' \
        "${TOOLBOX_GID}" \
        "${TOOLBOX_GROUPS//,/$'\n'}" \
        "${SUDO_GID}" |
    awk \
        -v primary="${TOOLBOX_SHARED_GID}" \
        'NF && $0 != primary && !seen[$0]++' |
    paste -sd, -
)"

# ===================================
# Passwordless sudo 
# ===================================

install -d -m 0755 /etc/sudoers.d

printf '%s\n' \
    '%sudo ALL=(ALL:ALL) NOPASSWD: ALL' \
    > /etc/sudoers.d/toolbox

chmod 0440 /etc/sudoers.d/toolbox

visudo -q -cf /etc/sudoers.d/toolbox

# ===================================
# Execute
# ===================================

umask 0002

exec setpriv \
    --reuid="${TOOLBOX_UID}" \
    --regid="${TOOLBOX_SHARED_GID}" \
    --groups="${session_groups}" \
    --inh-caps=-all \
    /bin/bash
