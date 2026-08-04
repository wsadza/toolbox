############################################################
# Copyright (c) 2026 Igor Sadza 
# Released under the GPLv3 license
# ----------------------------------------------------------
# 
# FILE: ./build/Dockerfile
# DESC: 
#
############################################################

# =============================================================================
# : Preflight 
# =============================================================================

ARG \
    DISTRIBUTION=debian \
    SUITE=trixie-slim \
    DIGEST=

# =============================================================================
# : Base 
# =============================================================================

FROM ${DISTRIBUTION}:${SUITE}${DIGEST:+@${DIGEST}} AS RUNTIME

# Build Time Arguments 
ARG \
    DEBIAN_FRONTEND=noninteractive

# ---------------------
# Base: Configure Locales

ARG \
    TZ=UTC \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_CTYPE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

ENV \
    LANG=${LANG} \
    LC_ALL=${LC_ALL} \
    LANGUAGE=${LANGUAGE} \
    TZ=${TZ}

RUN \
    echo "**** Base: User Tools ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            locales \
            ssl-cert \
            lsb-release \
            tzdata \
            sudo \
    && \
    echo "**** Set locale and timezone ****" \
        && sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen \
        && locale-gen ${LANG} \
        && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
        && echo "${TZ}" > /etc/timezone \
        && localedef -i en_US -f UTF-8 en_US.UTF-8 \
        && dpkg-reconfigure --frontend=noninteractive locales \
        && update-locale LANG=$LANG \
    && \
    echo "**** Section cleanup ****" \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/cache/apt/* \
            /var/tmp/* \
            /tmp/*

# -----------------------------------------------
# Base: Configure user 

ARG \
    USER_NAME=monke \
    USER_UID=1000 \
    USER_GID=1000

RUN \
    echo "**** Base: User Configure ****" \
      && groupadd \
        --gid ${USER_GID} \
        ${USER_NAME} \
      && useradd \
        --uid "${USER_UID}" \
        --gid "${USER_GID}" \
        --shell /bin/bash \
        --create-home \
        --home-dir "/home/${USER_NAME}" \
        "${USER_NAME}" \
    && \
    echo "**** Base: Configure SUDO Privileges ****" \
        && usermod -aG sudo ${USER_NAME} \
        && printf '%s\n' \
            "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" \
            > "/etc/sudoers.d/${USER_NAME}" \
        && chmod 0440 "/etc/sudoers.d/${USER_NAME}"

# =============================================================================
# : Core
# =============================================================================

# -----------------------------------------------
# Core: Neovim (BIN)

ARG \
    INSTALL_NEOVIM="false" \
    NEOVIM_VERSION="latest"

RUN \
    echo "**** Core: Install Neovim | Version: ${NEOVIM_VERSION} ****" \
    && \
    if [ "${INSTALL_NEOVIM}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            curl \
            jq \
    && \
    echo "**** Fetching Release URL ****" \
        && API_URL="https://api.github.com/repos/neovim/neovim" \
        && if [ "$NEOVIM_VERSION" = "latest" ]; then \
              NEOVIM_VERSION="$(\
                curl -fsSL ${API_URL}/releases/latest \
                | jq -r .tag_name \
              )"; \
           fi \
        && RELEASE_URL="$( \
             curl -fsSL "${API_URL}/releases?per_page=100" | \
               jq -r --arg VERSION "${NEOVIM_VERSION}" \
               '.[] \
               | select( \
                   .tag_name == $VERSION \
               ) \
               | .assets[] \
               | select( \
                   .browser_download_url \
                   | contains("nvim-linux-x86_64") \
                     and endswith(".tar.gz") \
               ) \
               | .browser_download_url' \
           )" \
    && \
    echo "**** Installing Release ****" \
        && curl -o /tmp/nvim.tar.gz -fsSL "${RELEASE_URL}" \
        && mkdir -p /opt/neovim \
        && tar -xzf /tmp/nvim.tar.gz \
            --strip-components=1 \
            --directory=/opt/neovim \
        && ln -sf /opt/neovim/bin/nvim /usr/local/bin/nvim \
        && ln -sf /usr/local/bin/nvim /usr/local/bin/vi \
        && vi --version \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Docker (GPG)

ARG \
    INSTALL_DOCKER="false" \
    DOCKER_GID=999 \
    DOCKER_CE_VERSION="" \
    DOCKER_CE_CLI_VERSION="" \
    CONTAINERD_VERSION="" \
    DOCKER_BUILDX_VERSION="" \
    DOCKER_COMPOSE_VERSION=""

RUN \
    echo "**** Core: Install Docker | Version: ${DOCKER_CE_VERSION:-latest} ****" \
    && \
    if [ "${INSTALL_DOCKER}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
    && \
    echo "**** Fetching GPG ****" \
      && install -m 0755 -d /etc/apt/keyrings \
      && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
      && chmod a+r /etc/apt/keyrings/docker.asc \
    && \
    echo "**** Configure Sources ****" \
      && SUITE=$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) \
      && printf '%s\n' \
          'Types: deb' \
          'URIs: https://download.docker.com/linux/debian' \
          "Suites: ${SUITE}" \
          'Components: stable' \
          "Architectures: $(dpkg --print-architecture)" \
          'Signed-By: /etc/apt/keyrings/docker.asc' \
         > /etc/apt/sources.list.d/docker.sources \
    && \
    echo "**** Installing ****" \
        && apt-get update \
        && apt search containerd.io \
        && apt search docker-buildx-plugin \
        && apt search docker-ce \
        && apt search docker-ce-cli \
        && apt search docker-compose-plugin \
        && apt-get install --no-install-recommends -y \
            docker-ce${DOCKER_CE_VERSION:+=${DOCKER_CE_VERSION}} \
            docker-ce-cli${DOCKER_CE_CLI_VERSION:+=${DOCKER_CE_CLI_VERSION}} \
            containerd.io${CONTAINERD_VERSION:+=${CONTAINERD_VERSION}} \
            docker-buildx-plugin${DOCKER_BUILDX_VERSION:+=${DOCKER_BUILDX_VERSION}} \
            docker-compose-plugin${DOCKER_COMPOSE_VERSION:+=${DOCKER_COMPOSE_VERSION}} \
    && \
    echo "**** Permisions ****" \
        && groupadd --gid "${DOCKER_GID}" docker-host \
        && usermod --append --groups docker-host ${USER_NAME} \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: K9S (BIN)

ARG \
    INSTALL_K9S="false" \
    K9S_VERSION="latest"

RUN \
    echo "**** Core: Install K9S | Version: ${K9S_VERSION} ****" \
    && \
    if [ "${INSTALL_K9S}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            curl \
            jq \
    && \
    echo "**** Fetching Release URL ****" \
        && API_URL="https://api.github.com/repos/derailed/k9s" \
        && if [ "$K9S_VERSION" = "latest" ]; then \
              K9S_VERSION="$(\
                curl -fsSL ${API_URL}/releases/latest \
                | jq -r .tag_name \
              )"; \
           fi \
        && RELEASE_URL="$( \
             curl -fsSL "${API_URL}/releases?per_page=100" | \
               jq -r --arg VERSION "${K9S_VERSION}" \
               '.[] \
               | select( \
                   .tag_name == $VERSION \
               ) \
               | .assets[] \
               | select( \
                   .browser_download_url \
                   | contains("Linux_amd64") \
                     and endswith(".tar.gz") \
               ) \
               | .browser_download_url' \
           )" \
    && \
    echo "**** Installing Release ****" \
        && curl -o /tmp/k9s.tar.gz -fsSL "${RELEASE_URL}" \
        && tar -xzf /tmp/k9s.tar.gz -C /opt \
        && ls /opt \
        && ln -sf \
            /opt/k9s \
            /usr/local/bin/k9s \
        && k9s version \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Helm (GPG)

ARG \
    INSTALL_HELM="false" \
    HELM_VERSION=""

RUN \
    echo "**** Core: Install Helm | Version: ${HELM_VERSION:-latest} ****" \
    && \
    if [ "${INSTALL_HELM}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
            gpg  \
            apt-transport-https \
    && \
    echo "**** Fetching GPG ****" \
      && curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey -o "${TMPDIR:-/tmp}/helm.gpg" \
      && gpg --dearmor --output /usr/share/keyrings/helm.gpg "${TMPDIR:-/tmp}/helm.gpg" > /dev/null \
    && \
    echo "**** Configure Sources ****" \
      && GPG_URL="https://packages.buildkite.com/helm-linux/helm-debian/any/" \
      && printf '%s\n' \
          "deb [signed-by=/usr/share/keyrings/helm.gpg] ${GPG_URL} any main" \
         > /etc/apt/sources.list.d/helm.list \
    && \
    echo "**** Installing ****" \
        && apt-get update \
        && apt search helm$ \
        && apt-get install --no-install-recommends -y \
          helm${HELM_VERSION:+=${HELM_VERSION}} \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Kubectl (GPG)

ARG \
    INSTALL_KUBECTL="false" \
    KUBECTL_VERSION=""

RUN \
    echo "**** Core: Install Kubectl | Version: ${KUBECTL_VERSION:-latest} ****" \
    && \
    if [ "${INSTALL_KUBECTL}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
            gpg  \
            apt-transport-https \
    && \
    echo "**** Fetching GPG ****" \
      && KUBECTL_MINOR="v$(printf '%s' "${KUBECTL_VERSION}" | cut -d. -f1,2)" \
      && curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBECTL_MINOR}/deb/Release.key -o "${TMPDIR:-/tmp}/kubernetes.gpg" \
      && gpg --dearmor --output /usr/share/keyrings/kubernetes.gpg "${TMPDIR:-/tmp}/kubernetes.gpg" > /dev/null \
    && \
    echo "**** Configure Sources ****" \
      && GPG_URL="https://pkgs.k8s.io/core:/stable:/${KUBECTL_MINOR}/deb/" \
      && printf '%s\n' \
          "deb [signed-by=/usr/share/keyrings/kubernetes.gpg] ${GPG_URL} /" \
         > /etc/apt/sources.list.d/kubernetes.list \
    && \
    echo "**** Installing ****" \
        && apt-get update \
        && apt search kubectl$ \
        && apt-get install --no-install-recommends -y \
          kubectl${KUBECTL_VERSION:+=${KUBECTL_VERSION}} \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Terraform (GPG)

ARG \
    INSTALL_TERRAFORM="false" \
    TERRAFORM_VERSION=""

RUN \
    echo "**** Core: Install Terraform | Version: ${TERRAFORM_VERSION:-latest} ****" \
    && \
    if [ "${INSTALL_TERRAFORM}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
            gpg  \
            apt-transport-https \
    && \
    echo "**** Fetching GPG ****" \
      && curl -fsSL https://apt.releases.hashicorp.com/gpg -o "${TMPDIR:-/tmp}/terraform.gpg" \
      && gpg --dearmor --output /usr/share/keyrings/terraform.gpg "${TMPDIR:-/tmp}/terraform.gpg" > /dev/null \
    && \
    echo "**** Configure Sources ****" \
      && SUITE=$(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) \
      && GPG_URL="https://apt.releases.hashicorp.com ${SUITE} main" \
      && printf '%s\n' \
          "deb [signed-by=/usr/share/keyrings/terraform.gpg] ${GPG_URL}" \
         > /etc/apt/sources.list.d/terraform.list \
    && \
    echo "**** Installing ****" \
        && apt-get update \
        && apt search terraform$ \
        && apt-get install --no-install-recommends -y \
          terraform${TERRAFORM_VERSION:+=${TERRAFORM_VERSION}} \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Azure-CLI (GPG)

ARG \
    INSTALL_AZURE_CLI="false" \
    AZURE_CLI_SUITE="bullseye" \
    AZURE_CLI_VERSION="" 

RUN \
    echo "**** Core: Install Azure-CLI | Version: ${AZURE_CLI_VERSION:-latest} ****" \
    && \
    if [ "${INSTALL_AZURE_CLI}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
    && \
    echo "**** Fetching GPG ****" \
      && install -m 0755 -d /etc/apt/keyrings \
      && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /etc/apt/keyrings/microsoft.asc \
      && chmod a+r /etc/apt/keyrings/microsoft.asc \
    && \
    echo "**** Configure Sources ****" \
      && printf '%s\n' \
          'Types: deb' \
          'URIs: https://packages.microsoft.com/repos/azure-cli/' \
          "Suites: ${AZURE_CLI_SUITE}" \
          'Components: stable' \
          "Architectures: $(dpkg --print-architecture)" \
          'Signed-By: /etc/apt/keyrings/microsoft.asc' \
         > /etc/apt/sources.list.d/microsoft.azure-cli.sources \
    && \
    echo "**** Installing ****" \
        && apt-get update \
        && apt search azure-cli$ \
        && apt-get install --no-install-recommends -y \
            azure-cli${AZURE_CLI_VERSION:+=${AZURE_CLI_VERSION}} \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Node.js (GPG)

ARG \
    INSTALL_NODE_JS="false" \
    NODE_JS_VERSION="" \
    NODE_JS_MAJOR=22

RUN \
    echo "**** Core: Install Node.js | Version: ${NODE_JS_VERSION:-latest} ****" \
    && \
    if [ "${INSTALL_NODE_JS}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
            gpg \
    && \
    echo "**** Fetching GPG ****" \
      && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o "${TMPDIR:-/tmp}/node.gpg" \
      && gpg --dearmor --output /usr/share/keyrings/node.gpg "${TMPDIR:-/tmp}/node.gpg" > /dev/null \
    && \
    echo "**** Configure Sources ****" \
      && GPG_URL="https://deb.nodesource.com/node_${NODE_JS_MAJOR}.x" \
      && printf '%s\n' \
          "deb [signed-by=/usr/share/keyrings/node.gpg] ${GPG_URL} nodistro main" \
         > /etc/apt/sources.list.d/node.list \
    && \
    echo "**** Installing ****" \
        && apt-get update \
        && apt search nodejs$  \
        && apt-get install --no-install-recommends -y \
            nodejs${NODE_JS_VERSION:+=${NODE_JS_VERSION}} \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# -----------------------------------------------
# Core: Install Gomplate 

ARG \
    INSTALL_GOMPLATE="false" \
    GOMPLATE_VERSION=""

RUN \
    echo "**** Core: Install Gomplate | Version: latest ****" \
    && \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
           curl \
           jq \
    && \
    echo "**** Installation ****" \
        && ARCHITECTURE="$(dpkg --print-architecture)" \
        && API_URL="https://api.github.com/repos/hairyhenderson/gomplate" \
        && BIN_RELEASE_URL="$( \
             curl -fsSL "${API_URL}/releases/latest" | \
               jq -r \
               --arg ARCHITECTURE "${ARCHITECTURE}" \
               '.assets[] \
               | select( \
                 .name \
                 | contains("linux") \
                   and contains($ARCHITECTURE) \
               ) \
               | .browser_download_url' \
           )" \
        && curl -o gomplate -fsSL "${BIN_RELEASE_URL}" \
        && chmod +x gomplate \
        && mv gomplate /usr/bin/gomplate \
    && \
    echo "**** Cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

# -----------------------------------------------
# Core: Install ACT 

ARG \
    INSTALL_ACT="false" \
    ACT_VERSION=""

RUN \
    echo "**** Core: Install ACT | Version: latest ****" \
    && \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
           curl \
           jq \
    && \
    echo "**** Installation ****" \
        && ARCHITECTURE="x86_64" \
        && API_URL="https://api.github.com/repos/nektos/act" \
        && RELEASE_URL="$( \
             curl -fsSL "${API_URL}/releases/latest" | \
               jq -r \
               --arg ARCHITECTURE "${ARCHITECTURE}" \
               '.assets[] \
               | select( \
                 .name \
                 | contains("Linux_x86_64") \
                   and contains($ARCHITECTURE) \
               ) \
               | .browser_download_url' \
           )" \
        && curl -o /tmp/act.tar.gz -fsSL "${RELEASE_URL}" \
        && mkdir -p /opt/act \
        && tar -xzf /tmp/act.tar.gz \
            --directory=/opt/act \
        && chmod +x /opt/act/act \
        && ln -sf /opt/act/act /usr/local/bin/act \
        && act --version \
    && \
    echo "**** Cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

# -----------------------------------------------
# Core: Miscellaneous
#

RUN \
    echo "**** Core: Miscellaneous (apt) ****" \
    && \
    echo "**** Install extra apt packages ****" \
      && apt-get update \
      && apt-get install -y --no-install-recommends \
          socat \
          dnsutils \
          bash-completion \
          git \
          tmux \
          lua5.1 \
          luarocks \
          golang \
          ripgrep \
          fd-find \
          libicu76 \
          pipx \
          python3 \
          build-essential \
          file \
          sqlite3 \
          rustup \
          libclang-dev \
          clang \
          supervisor \
          liquidprompt \
          ncurses-bin \
          figlet \
          lolcat \
          boxes \
          python3-pip \
          tree \
          iputils-ping \
    && \
    echo "**** Cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

# -----------------------------------------------
# Core: Python & NPM & Cargo packages 
#

# ${TREE_SITTER_CLI:+--version=${TREE_SITTER_CLI}} 
# ~ if arg is NON empty add --version

ARG \
    TREE_SITTER_CLI=

RUN \
    echo "**** Core: Miscellaneous (npm / cargo / pipx) ****" \
    && \
        echo "**** Install extra python packages ****" \
              && pipx install --global uv \
        && \
        if [ "${INSTALL_NODE_JS}" = "true" ]; \
        then \
        echo "**** Install extra node packages ****" \
              && npm install --global \
                  opencode-ai \
                  neovim \
              && npm cache clean --force; \
        fi \
        && \
        echo "**** Install extra cargo packages ****" \
              && rustup default stable \
              && cargo install \
                  tree-sitter-cli \
                  --locked \
                  --root /usr/local \
                  ${TREE_SITTER_CLI:+--version=${TREE_SITTER_CLI}} \
    && \
    echo "**** Clean installation caches ****" \
        && python3 -m pip cache purge

# =============================================================================
# : Config 
# =============================================================================

# -----------------------------------------------
# Config: Variables
#

ENV \
    SHELL=/bin/bash \
    TERM=xterm-256color \ 
    HOME=/home/${USER_NAME}

ENV \
    XDG_ROOT=/opt/toolbox

ENV \
    XDG_RUNTIME_DIR=/run/toolbox \
    XDG_CONFIG_HOME=${XDG_ROOT}/config \
    XDG_DATA_HOME=${XDG_ROOT}/share \
    XDG_STATE_HOME=${XDG_ROOT}/state \
    XDG_CACHE_HOME=${XDG_ROOT}/cache \
    XDG_BIN_HOME=${XDG_ROOT}/bin

# Node.js / npm
ENV \
    NPM_CONFIG_CACHE=${XDG_CACHE_HOME}/npm \
    NPM_CONFIG_HOME=${XDG_CONFIG_HOME}/npm \
    NPM_CONFIG_USERCONFIG=${XDG_CONFIG_HOME}/npm/npmrc \
    NPM_CONFIG_PYTHON=/usr/bin/python3

# Go
ENV \
    GOPATH=${XDG_DATA_HOME}/go \
    GOCACHE=${XDG_CACHE_HOME}/go/build \
    GOMODCACHE=${XDG_CACHE_HOME}/go/modules \
    GOTMPDIR=${XDG_RUNTIME_DIR}/go

# Rust
ENV \
    CARGO_HOME=${XDG_DATA_HOME}/cargo \
    CARGO_TARGET_DIR=${XDG_CACHE_HOME}/cargo/target

# uv
ENV \
    UV_TOOL_DIR=${XDG_DATA_HOME}/uv/tools \
    UV_TOOL_BIN_DIR=${XDG_BIN_HOME} \
    UV_CACHE_DIR=${XDG_CACHE_HOME}/uv

# Liquidprompt
ENV \
    LOCAL_RCFILE=${XDG_CONFIG_HOME}/liquidprompt/liquidpromptrc \
    LIQUIDPROMPT_THEME=powerline

# OpenCode
ENV \
    OPENCODE_HOME=${XDG_CONFIG_HOME}/opencode \
    OPENCODE_CONFIG=${XDG_CONFIG_HOME}/opencode/opencode.json

# Git
ENV \
    GIT_CONFIG_DIR=${XDG_CONFIG_HOME}/git \
    GIT_CONFIG_GLOBAL=${XDG_CONFIG_HOME}/git/gitconfig

# Docker 
ENV \
    DOCKER_CONFIG=${XDG_CONFIG_HOME}/docker

# Final Path
ENV \
    PATH=${XDG_BIN_HOME}:${CARGO_HOME}/bin:${GOPATH}/bin:${PATH}

# =============================================================================
# : Postflight 
# =============================================================================

# -----------------------------------------------
# Postflight: Create workspace targets 
#

RUN \
    echo "**** Postflight: Create workspace targets ****" \
    && \
    install -d \
        -o "${USER_UID}" \
        -g "${USER_GID}" \
        -m 0755 \
        \
        "${XDG_CONFIG_HOME}" \
        "${XDG_DATA_HOME}" \
        "${XDG_STATE_HOME}" \
        "${XDG_CACHE_HOME}" \
        \
        "${NPM_CONFIG_CACHE}" \
        "${NPM_CONFIG_USERCONFIG}" \
        \
        "${GOPATH}" \
        "${GOCACHE}" \
        "${GOMODCACHE}" \
        "${GOTMPDIR}" \
        \
        "${CARGO_HOME}" \
        "${CARGO_TARGET_DIR}" \
        \
        "${UV_TOOL_DIR}" \
        "${UV_TOOL_BIN_DIR}" \
        \
        "${OPENCODE_HOME}" \
        \
        "${GIT_CONFIG_DIR}" \
    && \
    install -d \
        -o "${USER_UID}" \
        -g "${USER_GID}" \
        -m 0700 \
        "${XDG_RUNTIME_DIR}" \
    && \
    install \
        -o "${USER_UID}" \
        -g "${USER_GID}" \
        -m 0644 \
        /dev/null \
        "${NPM_CONFIG_USERCONFIG}"

# =============================================================================
# : User Space 
# =============================================================================

# Switch to non-root user.
USER ${USER_NAME}

# -----------------------------------------------
# Postflight: Copy overlay and change owner 

COPY \
    --chown=${USER_UID}:${USER_GID} \
    rootfs / 

COPY \
    --chown=${USER_UID}:${USER_GID} \
    --chmod=0755 \
    rootfs/entrypoint.sh /entrypoint.sh

# -----------------------------------------------
# Postflight: Installing nvim plugins 
#

RUN \
    if [ "${INSTALL_NEOVIM}" = "true" ]; \
    then \
      echo "**** Fetch Nvim Plugins ****" \
          && vi --headless \
              "+Lazy! sync" +qa \
          && vi --headless \
              "+lua require('nvim-treesitter').install(vim.g.treesitter_parsers):wait()" \
              +qa \
          && vi --headless \
              "+MasonToolsInstallSync" +qa; \
    fi

# =============================================================================
# : Execute 
# =============================================================================

# Switch to non-root user.
USER ${USER_NAME}

# Set working target
WORKDIR ${HOME} 

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
