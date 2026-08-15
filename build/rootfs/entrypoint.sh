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

# ===================================
# Helpers
# ===================================

log() {
    printf '[entrypoint] %s\n' "$*" >&2
}

# ===================================
# Runtime User Mapping
# ===================================

USER_NAME=monke
USER_HOME=/opt/home

export USER_NAME
export USER_HOME
export HOME="${USER_HOME}"

log "Entrypoint started"
log "USER_NAME=${USER_NAME}"
log "USER_HOME=${USER_HOME}"
log "HOME=${HOME}"

# /opt/home must exist and should be the host-home bind mount.
if [[ ! -d "${USER_HOME}" ]]; then
    log "ERROR: user home does not exist: ${USER_HOME}"
    exit 1
fi

# Current container user identity.
OLD_UID="$(id -u "${USER_NAME}")"
OLD_GID="$(id -g "${USER_NAME}")"

# Ownership of the mounted host home.
HOST_UID="$(stat -c '%u' "${USER_HOME}")"
HOST_GID="$(stat -c '%g' "${USER_HOME}")"

export OLD_UID
export OLD_GID
export HOST_UID
export HOST_GID

log "Current container identity: ${OLD_UID}:${OLD_GID}"
log "Mounted home ownership:     ${HOST_UID}:${HOST_GID}"

# --------------------
# Change primary group
# --------------------

if [[ "${OLD_GID}" != "${HOST_GID}" ]]; then
    log "Changing ${USER_NAME} GID: ${OLD_GID} -> ${HOST_GID}"

    # A group with the target GID may already exist.
    EXISTING_GROUP="$(getent group "${HOST_GID}" | cut -d: -f1 || true)"

    if [[ -n "${EXISTING_GROUP}" ]] && [[ "${EXISTING_GROUP}" != "${USER_NAME}" ]]; then
        log "Target GID ${HOST_GID} already belongs to group: ${EXISTING_GROUP}"

        usermod \
            --gid "${HOST_GID}" \
            "${USER_NAME}"
    else
        groupmod \
            --gid "${HOST_GID}" \
            "${USER_NAME}"
    fi
else
    log "GID already matches mounted home"
fi

# --------------------
# Change user UID
# --------------------

if [[ "${OLD_UID}" != "${HOST_UID}" ]]; then
    log "Changing ${USER_NAME} UID: ${OLD_UID} -> ${HOST_UID}"

    EXISTING_USER="$(getent passwd "${HOST_UID}" | cut -d: -f1 || true)"

    if [[ -n "${EXISTING_USER}" ]] && [[ "${EXISTING_USER}" != "${USER_NAME}" ]]; then
        log "ERROR: target UID ${HOST_UID} already belongs to user: ${EXISTING_USER}"
        exit 1
    fi

    usermod \
        --uid "${HOST_UID}" \
        "${USER_NAME}"
else
    log "UID already matches mounted home"
fi

# --------------------
# Ensure correct home
# --------------------

CURRENT_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6)"

if [[ "${CURRENT_HOME}" != "${USER_HOME}" ]]; then
    log "Changing passwd home: ${CURRENT_HOME} -> ${USER_HOME}"

    usermod \
        --home "${USER_HOME}" \
        "${USER_NAME}"
fi

export HOME="${USER_HOME}"

log "Mapped user:"
getent passwd "${USER_NAME}" >&2

# ===================================
# Docker socket supplementary group
# ===================================

if [[ -S /var/run/docker.sock ]]; then
    DOCKER_GID="$(stat -c '%g' /var/run/docker.sock)"

    log "Docker socket detected"
    log "Docker socket GID=${DOCKER_GID}"

    DOCKER_GROUP="$(getent group "${DOCKER_GID}" | cut -d: -f1 || true)"

    if [[ -z "${DOCKER_GROUP}" ]]; then
        DOCKER_GROUP=docker-host

        log "Creating ${DOCKER_GROUP} with GID ${DOCKER_GID}"

        groupadd \
            --gid "${DOCKER_GID}" \
            "${DOCKER_GROUP}"
    else
        log "Docker socket group already exists: ${DOCKER_GROUP}"
    fi

    if ! id -nG "${USER_NAME}" | tr ' ' '\n' | grep -qx "${DOCKER_GROUP}"; then
        log "Adding ${USER_NAME} to ${DOCKER_GROUP}"

        usermod \
            --append \
            --groups "${DOCKER_GROUP}" \
            "${USER_NAME}"
    fi
fi

# ===================================
# Load global interactive Bash
# configuration fragments
# ===================================

BASHRC='/etc/bash.bashrc'
BASHRC_MARKER='# BEGIN bash.bashrc.d loader'

if ! grep -Fq "${BASHRC_MARKER}" "${BASHRC}"; then
    log "Installing bash.bashrc.d loader"

    cat >> "${BASHRC}" <<'EOF'

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

# ===================================
# Execute all container init scripts
# ===================================

run_init_scripts() {
    local directory="$1"
    local pattern="$2"
    local script

    [[ -d "${directory}" ]] || return 0

    while IFS= read -r -d '' script; do
        log "Executing init script: ${script}"

        bash "${script}"

        log "Finished init script: ${script}"
    done < <(
        find "${directory}" \
            -maxdepth 1 \
            -type f \
            -name "${pattern}" \
            -print0 |
        sort -z
    )
}

run_init_scripts \
    '/etc/cont-init.d/core' \
    '*.sh'

run_init_scripts \
    '/etc/cont-init.d/optional' \
    '*.sh'

# ===================================
# Prepare run/start scripts
# ===================================

make_executable_scripts() {
    local directory="$1"
    local pattern="$2"
    local script

    [[ -d "${directory}" ]] || return 0

    while IFS= read -r -d '' script; do
        chmod +x "${script}"
    done < <(
        find "${directory}" \
            -maxdepth 1 \
            -type f \
            -name "${pattern}" \
            -print0 |
        sort -z
    )
}

make_executable_scripts \
    '/usr/bin' \
    '*.sh'

# ===================================
# Final state
# ===================================

log "Final user identity:"
id "${USER_NAME}" >&2

log "Final passwd entry:"
getent passwd "${USER_NAME}" >&2

log "Final HOME=${HOME}"

log "/opt/home ownership:"
stat \
    --printf='owner=%u:%g (%U:%G)\n' \
    "${USER_HOME}" >&2

log "Container initialization complete"

# ===================================
# Execute
# ===================================

exec sleep infinity
