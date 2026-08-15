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
# Logging
# ===================================

log() {
    printf '[entrypoint] %s\n' "$*" >&2
}

passwd_home() {
    getent passwd "${USER_NAME}" | cut -d: -f6
}

dump_user_state() {
    local current_passwd_home

    current_passwd_home="$(passwd_home 2>/dev/null || true)"

    log "============================================================"
    log "User state"
    log "------------------------------------------------------------"
    log "USER_NAME=${USER_NAME:-unset}"
    log "USER_HOME=${USER_HOME:-unset}"
    log "HOME=${HOME:-unset}"
    log "HOST_HOME=${HOST_HOME:-unset}"
    log "passwd HOME=${current_passwd_home:-unknown}"

    log "id:"
    id "${USER_NAME}" >&2 || true

    log "passwd:"
    getent passwd "${USER_NAME}" >&2 || true

    log "/etc/passwd metadata:"
    stat \
        --printf='  owner=%U:%G mode=%a size=%s mtime=%y ctime=%z\n' \
        /etc/passwd >&2 || true

    log "============================================================"
}

check_home() {
    local actual_home

    actual_home="$(passwd_home 2>/dev/null || true)"

    log "HOME check:"
    log "  expected passwd home : ${USER_HOME}"
    log "  actual passwd home   : ${actual_home:-unknown}"
    log "  environment HOME     : ${HOME:-unset}"

    if [[ -n "${actual_home}" ]] && [[ "${actual_home}" != "${USER_HOME}" ]]; then
        log "WARNING: passwd home differs from expected USER_HOME"
    fi

    if [[ "${HOME:-}" != "${USER_HOME}" ]]; then
        log "WARNING: environment HOME differs from expected USER_HOME"
    fi
}

# ===================================
# Runtime User Mapping
# ===================================

export USER_NAME=monke
export USER_HOME=/opt/home

log "Entrypoint started"
log "PID=$$"

dump_user_state
check_home

export OLD_UID="$(id -u "${USER_NAME}")"
export OLD_GID="$(id -g "${USER_NAME}")"

log "Reading host UID/GID from HOST_HOME=${HOST_HOME}"

export HOST_UID="$(stat -c '%u' "${HOST_HOME}")"
export HOST_GID="$(stat -c '%g' "${HOST_HOME}")"

log "Runtime identity mapping:"
log "  OLD_UID=${OLD_UID}"
log "  OLD_GID=${OLD_GID}"
log "  HOST_UID=${HOST_UID}"
log "  HOST_GID=${HOST_GID}"

# --------------------
# Change primary group.
# --------------------

log "Checking primary group"

if [[ "${OLD_GID}" != "${HOST_GID}" ]]; then
    log "Changing ${USER_NAME} GID: ${OLD_GID} -> ${HOST_GID}"

    groupmod \
        --gid "${HOST_GID}" \
        "${USER_NAME}"

    log "Primary group changed"
else
    log "Primary GID already matches host GID"
fi

dump_user_state
check_home

# --------------------
# Change user UID.
# --------------------

log "Checking user UID"

if [[ "${OLD_UID}" != "${HOST_UID}" ]]; then
    log "Changing ${USER_NAME} UID: ${OLD_UID} -> ${HOST_UID}"

    usermod \
        --uid "${HOST_UID}" \
        "${USER_NAME}"

    log "User UID changed"
else
    log "User UID already matches host UID"
fi

dump_user_state
check_home

# --------------------
# Docker socket supplementary group.
# --------------------

if [[ -S /var/run/docker.sock ]]; then
    log "Docker socket detected"

    DOCKER_GID="$(stat -c '%g' /var/run/docker.sock)"

    log "Docker socket GID=${DOCKER_GID}"

    if ! getent group "${DOCKER_GID}" >/dev/null; then
        log "Creating docker-host group with GID ${DOCKER_GID}"

        groupadd \
            --gid "${DOCKER_GID}" \
            docker-host
    else
        log "Group with GID ${DOCKER_GID} already exists"
    fi

    log "Adding ${USER_NAME} to supplementary Docker group ${DOCKER_GID}"

    usermod \
        --append \
        --groups "${DOCKER_GID}" \
        "${USER_NAME}"

    dump_user_state
    check_home
else
    log "Docker socket not present"
fi

# ===================================
# Load global interactive Bash
# configuration fragments.
# ===================================

BASHRC='/etc/bash.bashrc'
BASHRC_MARKER='# BEGIN bash.bashrc.d loader'

log "Checking global Bash configuration loader"

if ! grep -Fq "${BASHRC_MARKER}" "${BASHRC}"; then
    log "Installing /etc/bash.bashrc.d loader into ${BASHRC}"

    tee -a "${BASHRC}" >/dev/null <<'EOF'

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

    log "Bash configuration loader installed"
else
    log "Bash configuration loader already present"
fi

dump_user_state
check_home

# ===================================
# Execute all container init scripts
# ===================================

run_init_scripts() {
    local directory=$1
    local prefix=$2
    local script

    if [[ ! -d "${directory}" ]]; then
        log "Init directory does not exist: ${directory}"
        return 0
    fi

    log "Scanning init directory:"
    log "  directory=${directory}"
    log "  pattern=${prefix}"

    while IFS= read -r -d '' script; do
        log "------------------------------------------------------------"
        log "Executing init script:"
        log "  ${script}"

        log "State BEFORE ${script}"
        dump_user_state
        check_home

        bash "${script}"

        log "State AFTER ${script}"
        dump_user_state
        check_home

        log "Finished init script:"
        log "  ${script}"
        log "------------------------------------------------------------"
    done < <(
        find "${directory}" \
            -maxdepth 1 \
            -type f \
            -name "${prefix}" \
            -print0 |
            sort -z
    )
}

log "Starting core init scripts"

run_init_scripts \
    '/etc/cont-init.d/core' \
    '*.sh'

log "Core init scripts completed"

dump_user_state
check_home

log "Starting optional init scripts"

run_init_scripts \
    '/etc/cont-init.d/optional' \
    '*.sh'

log "Optional init scripts completed"

dump_user_state
check_home

# ===================================
# Prepare run/start scripts
# ===================================

make_executable_scripts() {
    local directory=$1
    local prefix=$2
    local script

    if [[ ! -d "${directory}" ]]; then
        log "Script directory does not exist: ${directory}"
        return 0
    fi

    log "Making matching scripts executable:"
    log "  directory=${directory}"
    log "  pattern=${prefix}"

    while IFS= read -r -d '' script; do
        log "chmod +x ${script}"
        chmod +x "${script}"
    done < <(
        find "${directory}" \
            -maxdepth 1 \
            -type f \
            -name "${prefix}" \
            -print0 |
            sort -z
    )
}

make_executable_scripts \
    '/usr/bin' \
    '*.sh'

# ===================================
# Final State
# ===================================

log "Container initialization complete"

dump_user_state
check_home

log "Selected environment variables:"
env |
    sort |
    grep -E \
        '^(HOME|HOST_HOME|USER|USER_NAME|USER_HOME|OLD_UID|OLD_GID|HOST_UID|HOST_GID|XDG_.*)=' \
        >&2 || true

log "Final /etc/passwd entry:"
getent passwd "${USER_NAME}" >&2 || true

# ===================================
# Execute
# ===================================

log "Starting container keepalive process"

exec sleep infinity
