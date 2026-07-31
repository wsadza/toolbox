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

ENV \
    XDG_RUNTIME_DIR=/run/user/workspace

RUN \
    echo "**** Base: User Configure ****" \
      && groupadd \
        --gid ${USER_GID} \
        ${USER_NAME} \
      && useradd \
        --uid "${USER_UID}" \
        --gid "${USER_GID}" \
        --create-home \
        --home-dir "/opt/home" \
        --shell /bin/bash \
        "${USER_NAME}" \
      && mkdir -p "/opt/home" \
    && \
    echo "**** Base: Configure SUDO Privileges ****" \
        && usermod -aG sudo ${USER_NAME} \
        && printf '%s\n' \
            "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" \
            > "/etc/sudoers.d/${USER_NAME}" \
        && chmod 0440 "/etc/sudoers.d/${USER_NAME}" \
    && \
    echo "**** Base: Configure XDG_RUNTIME_DIR ****" \
        && mkdir -p ${XDG_RUNTIME_DIR} \
        && chown -R ${USER_UID}:${USER_UID} ${XDG_RUNTIME_DIR} \
        && chmod 0700 ${XDG_RUNTIME_DIR} 

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
        && tar -xzf /tmp/nvim.tar.gz -C /opt \
        && ln -sf \
            /opt/nvim-linux-x86_64/bin/nvim \
            /usr/local/bin/vi \
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
      && GPG_URL="https://pkgs.k8s.io/core:/stable:/v1.36/deb/" \
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
# Core: LLAMA (BIN)

ARG \
    INSTALL_LLAMA_CPP="false" \
    LLAMA_CPP_REF="master"

RUN \
    echo "**** Core: Install LLAMA | Reference: ${LLAMA_CPP_REF} ****" \
    && \
    if [ "${INSTALL_LLAMA_CPP}" = "true" ]; then \
        apt-get update \
        && apt-get install --no-install-recommends -y \
            cmake \
            curl \
            git \
            libcurl4-openssl-dev \
            cmake \
            build-essential \
        && git clone \
            --depth 1 \
            --branch "${LLAMA_CPP_REF}" \
            https://github.com/ggml-org/llama.cpp.git \
            /tmp/llama.cpp \
        && cmake \
            -S /tmp/llama.cpp \
            -B /tmp/llama.cpp/build \
            -DGGML_NATIVE=OFF \
            -DLLAMA_CURL=ON \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_BUILD_TYPE=Release \
        && cmake \
            --build /tmp/llama.cpp/build \
            --config Release \
            --target llama-server llama-cli \
            --parallel "$(nproc)" \
        && install -m 0755 \
            /tmp/llama.cpp/build/bin/llama-server \
            /usr/local/bin/llama-server \
        && install -m 0755 \
            /tmp/llama.cpp/build/bin/llama-cli \
            /usr/local/bin/llama-cli \
        && apt-get clean \
        && rm -rf \
            /tmp/llama.cpp \
            /var/lib/apt/lists/*; \
    fi

# -----------------------------------------------
# Core: AIChat (BIN)

ARG \
    INSTALL_AICHAT="false" \
    AICHAT_VERSION="latest"

RUN \
    echo "**** Core: Install AIChat | Version: ${AICHAT_VERSION} ****" \
    && \
    if [ "${INSTALL_AICHAT}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            curl \
            jq \
    && \
    echo "**** Fetching Release URL ****" \
        && API_URL="https://api.github.com/repos/sigoden/aichat" \
        && if [ "$AICHAT_VERSION" = "latest" ]; then \
              AICHAT_VERSION="$(\
                curl -fsSL ${API_URL}/releases/latest \
                | jq -r .tag_name \
              )"; \
           fi \
        && RELEASE_URL="$( \
             curl -fsSL "${API_URL}/releases?per_page=100" | \
               jq -r --arg VERSION "${AICHAT_VERSION}" \
               '.[] \
               | select( \
                   .tag_name == $VERSION \
               ) \
               | .assets[] \
               | select( \
                   .browser_download_url \
                   | contains("x86_64-unknown-linux-musl") \
                     and endswith(".tar.gz") \
               ) \
               | .browser_download_url' \
           )" \
    && \
    echo "**** Installing Release ****" \
        && echo "${RELEASE_URL}" \
        && curl -o /tmp/aichat.tar.gz -fsSL "${RELEASE_URL}" \
        && tar -xzf /tmp/aichat.tar.gz -C /opt \
        && ln -sf \
            /opt/aichat \
            /usr/local/bin/aichat \
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
# Core: AIChat (BIN)

#ARG \
#    INSTALL_AI_STACK="false" \
#    AI_CHAT_VERSION="latest" \
#    AIDER_VERSION="latest" \
#    LLM_CLI_VERSION="latest" \
#
#RUN \
#    echo "**** Core: Install AIConsoleStack ****" \
#    && \
#    if [ "${INSTALL_AI_STACK}" = "true" ]; \
#    then \
#    echo "**** Prepare ****" \
#        && apt-get update \
#        && apt-get install --no-install-recommends -y \
#            python3 \
#            pipx \
#            curl \
#            jq \
#    && \
#
#    fi
#
# -----------------------------------------------
# Core: Install Gomplate 

RUN \
    echo "**** Core: Install Gomplate ****" \
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
# Core: Miscellaneous
#

RUN \
    echo "**** Core: Miscellaneous  ****" \
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
          build-essential \
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
    && \
    echo "**** Cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*

# =============================================================================
# : Config 
# =============================================================================

# -----------------------------------------------
# Postflight: Installing nvim plugins dependencies
#

ARG \
    TREE_SITTER_CLI=latest

RUN \
    echo "**** Postflight: Miscellaneous  ****" \
    && \
        echo "**** Install extra python packages ****" \
              && pipx install --global llm uv \
        && \
        echo "**** Install extra node packages ****" \
              && npm install --global opencode-ai \
              && npm install --global neovim \
        && \
        echo "**** Install extra cargo packages ****" \
              && rustup default stable \
              && cargo install \
                  tree-sitter-cli \
                  --locked \
                  --version ${TREE_SITTER_CLI} \
                  --root /usr/local \
    && \
    echo "**** Clean installation caches ****" \
      && npm cache clean --force \
      && python3 -m pip cache purge

# -----------------------------------------------
# Postflight: Variables
#

ENV \
    XDG_CONFIG_HOME=${XDG_RUNTIME_DIR}/.config \
    XDG_DATA_HOME=${XDG_RUNTIME_DIR}/.local/.share \
    XDG_STATE_HOME=${XDG_RUNTIME_DIR}/.local/.state \
    XDG_CACHE_HOME=${XDG_RUNTIME_DIR}/.local/.cache \
    XDG_BIN_HOME=${XDG_RUNTIME_DIR}/.local/.bin \ 
    HOME=/opt/home \
    SHELL=/bin/bash \
    TERM=xterm-256color

ENV \
    NPM_CONFIG_CACHE=${XDG_RUNTIME_DIR}/npm-cache \
    NPM_CONFIG_USERCONFIG=${XDG_RUNTIME_DIR}/.npmrc \
    NPM_CONFIG_PYTHON=/usr/bin/python3

ENV \
    GOPATH=${XDG_RUNTIME_DIR}/go/gopath \
    GOCACHE=${XDG_RUNTIME_DIR}/go/build-cache \
    GOMODCACHE=${XDG_RUNTIME_DIR}/go/module-cache \
    GOTMPDIR=${XDG_RUNTIME_DIR}/go/tmp

ENV \
    AI_HOST=0.0.0.0 \
    AI_PORT=8080 \
    LLAMA_CACHE=${XDG_RUNTIME_DIR}/.cache/llama.cpp \
    LLAMA_ARG_CTX_SIZE=8192 \
    LLAMA_ARG_N_GPU_LAYERS=0 \
    LLAMA_ARG_HOST=0.0.0.0 \
    LLAMA_ARG_PORT=8080

ENV \
    CARGO_HOME="${XDG_DATA_HOME}/cargo" \
    CARGO_TARGET_DIR="${XDG_CACHE_HOME}/cargo/target"

ENV \
    SUPERVISOR_PORT=9091

ENV \
    UV_TOOL_DIR="${XDG_RUNTIME_DIR}/uv/tools" \
    UV_TOOL_BIN_DIR="${XDG_BIN_HOME}" 

ENV \
    LLM_USER_PATH="${XDG_RUNTIME_DIR}/.config/llm"

ENV \
    LOCAL_RCFILE="${XDG_RUNTIME_DIR}/.config/liqiudpromptrc"

ENV \
    OPENCODE_CONFIG="${XDG_RUNTIME_DIR}/.config/opencode/opencode.json"

ENV \
    PATH="${CARGO_HOME}/bin:${GOPATH}/bin:${PATH}:${XDG_BIN_HOME}"

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
        "${XDG_CONFIG_HOME}" \
        "${XDG_DATA_HOME}" \
        "${XDG_STATE_HOME}" \
        "${XDG_CACHE_HOME}" \
        "${NPM_CONFIG_CACHE}" \
        "${GOPATH}" \
        "${GOCACHE}" \
        "${GOMODCACHE}" \
        "${GOTMPDIR}" \
        "${CARGO_HOME}" \
        "${CARGO_TARGET_DIR}" \
        "${UV_TOOL_DIR}" \
        "${UV_TOOL_BIN_DIR}" \
        "${LLM_USER_PATH}" \
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

# -----------------------------------------------
# Postflight: AI Model 
#

ARG \
    DOWNLOAD_AI_MODEL="false" \
    AI_MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf" \
    AI_MODEL_NAME="qwen2.5-coder-1.5b-instruct-q4_k_m.gguf" \
    AI_MODEL_PATH="/models" \
    AI_MODEL_ALIAS="qwen2.5-coder"

ENV \
    LLAMA_ARG_MODEL="${AI_MODEL_PATH}/${AI_MODEL_NAME}" \
    LLAMA_ARG_ALIAS="${AI_MODEL_ALIAS}"

RUN \
    echo "**** Postflight: Download AI Model ****" \
    && \
    if [ "${DOWNLOAD_AI_MODEL}" = "true" ]; \
    then \
    echo "**** Prepare ****" \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
            ca-certificates \
            curl \
    && \
    echo "**** Fetch AI Model ****" \
        && mkdir -p ${AI_MODEL_PATH} \
        && curl \
             --fail \
             --progress-bar \
             --location \
             --retry 5 \
             --output "${LLAMA_ARG_MODEL}" \
             "${AI_MODEL_URL}" \
        && chown "${USER_UID}:${USER_GID}" "${LLAMA_ARG_MODEL}" \
        && chmod 0644 "${LLAMA_ARG_MODEL}" \
    && \
    echo "**** Cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/*; \
    fi

# =============================================================================
# : User Space 
# =============================================================================


#      rm -rf \
#          "${XDG_CACHE_HOME}" \
#          "${XDG_DATA_HOME}" \
#          /root/.cargo/registry \
#          /root/.cargo/git \
#          /root/.cargo/.package-cache \
#          /tmp/* \
#          /var/tmp/*
#
# Switch to non-root user.
USER ${USER_NAME}

# -----------------------------------------------
# Postflight: Installing nvim plugins dependencies
#
#
#ARG \
#    TREE_SITTER_CLI=latest
#
#RUN \
#    if [ "${INSTALL_NEOVIM}" = "true" ]; \
#    then \
#        echo "**** Fetch Nvim Plugins Dependencies ****" \
#          && rustup default stable \
#          && cargo install \
#              tree-sitter-cli \
#              --locked \
#              --version ${TREE_SITTER_CLI} \
#              --root /usr/local; \
#    fi

# -----------------------------------------------
# Postflight: Install noevim 

#RUN \
#    if [ "${INSTALL_NEOVIM}" = "true" ] \
#    && [ "${INSTALL_NODE_JS}" = "true" ]; then \
#        echo "**** Install Node Nvim Provider ****"; \
#        npm install -g neovim; \
#    fi

# -----------------------------------------------
# Postflight: Copy overlay and change owner 

COPY \
    --chown=${USER_UID}:${USER_GID} \
    overlay / 

COPY \
    --chown=${USER_UID}:${USER_GID} \
    --chmod=0755 \
    overlay/entrypoint.sh /entrypoint.sh

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

# -----------------------------------------------
# Postflight: overlay permissions 
#

#RUN \
#    echo "**** Postflight: Changing Permissions ****" \
#    && \
#        echo "Make sure that everything under ${XDG_RUNTIME_DIR} belongs to user" \
#            && chown -R "${USER_UID}:${USER_GID}" "${XDG_RUNTIME_DIR}" \
#            && chmod -R a+rwX ${XDG_RUNTIME_DIR} \
#        && \
#        echo "Make sure that /entrypoint.sh belongs to user" \
#            && chown -R ${USER_UID}:${USER_GID} /entrypoint.sh \
#            && chmod 755 /entrypoint.sh

#ENV \
#    UV_TOOL_DIR=${XDG_RUNTIME_DIR}/config/.local/share/uv/tools \
#    UV_TOOL_BIN_DIR=${XDG_RUNTIME_DIR}/config/.local/bin \
#    PATH=/config/.local/bin:${PATH}

#RUN \
#    uv tool install \
#      --force \
#      --python python3.12 \
#      aider-chat@latest

# =============================================================================
# : Execute 
# =============================================================================

# Switch to non-root user.
USER ${USER_NAME}

# Set working target
WORKDIR ${HOME} 

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
