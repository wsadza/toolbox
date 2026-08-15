# docker-bake.hcl

variable "REGISTRY" {
  default = "ghcr.io"
}

variable "IMAGE" {
  default = "wsadza/toolbox"
}

variable "TAG" {
  default = "develop"
}


# -----------------------------------------------------------------------------
# Base image
# -----------------------------------------------------------------------------

variable "DISTRIBUTION" {
  default = "debian"
}

variable "SUITE" {
  default = "trixie-slim"
}

variable "DIGEST" {
  default = "sha256:020c0d20b9880058cbe785a9db107156c3c75c2ac944a6aa7ab59f2add76a7bd"
}

# =============================================================================
# User 
# =============================================================================

variable "USER_NAME" {
  default = "monke"
}

variable "DOCKER_GID" {
  default = "109"
}

variable "USER_UID" {
  default = "1000"
}

# =============================================================================
# Tool versions
# =============================================================================


variable "NEOVIM_VERSION" {
  default = "latest"
}

variable "K9S_VERSION" {
  default = "latest"
}

variable "HELM_VERSION" {
  default = ""
}

variable "KUBECTL_VERSION" {
  default = ""
}

variable "TERRAFORM_VERSION" {
  default = ""
}

variable "AZURE_CLI_VERSION" {
  default = ""
}

variable "NODE_JS_MAJOR" {
  default = "22"
}

variable "NODE_JS_VERSION" {
  default = ""
}

variable "TREE_SITTER_CLI" {
  default = "0.26.11"
}

variable "NEOVIM_NPM" {
  default = "5.4.0"
}

variable "OPENCODE_AI" {
  default = "1.18.13"
}

variable "UV" {
  default = "0.12.1"
}


# -----------------------------------------------------------------------------
# Main image
# -----------------------------------------------------------------------------

target "image" {
  context    = "build"
  dockerfile = "Dockerfile"

  args = {
    DISTRIBUTION      = DISTRIBUTION
    SUITE             = SUITE
    DIGEST            = DIGEST

    INSTALL_NEOVIM    = "true"
    INSTALL_DOCKER    = "true"
    INSTALL_K9S       = "true"
    INSTALL_HELM      = "true"
    INSTALL_KUBECTL   = "true"
    INSTALL_TERRAFORM = "true"
    INSTALL_AZURE_CLI = "true"
    INSTALL_NODE_JS   = "true"
    INSTALL_GOMPLATE  = "true"

    NEOVIM_VERSION        = NEOVIM_VERSION
    K9S_VERSION           = K9S_VERSION
    HELM_VERSION          = HELM_VERSION
    KUBECTL_VERSION       = KUBECTL_VERSION
    TERRAFORM_VERSION     = TERRAFORM_VERSION
    AZURE_CLI_VERSION     = AZURE_CLI_VERSION

    NODE_JS_MAJOR         = NODE_JS_MAJOR
    NODE_JS_VERSION       = NODE_JS_VERSION

    CARGO_TREE_SITTER_CLI = CARGO_TREE_SITTER_CLI
    NPM_NEOVIM            = NPM_NEOVIM_NPM
    NPM_OPENCODE_AI       = NPM_OPENCODE_AI
    PIPX_UV               = PIPX_UV
  }

  tags = [
    "${REGISTRY}/${IMAGE}:${TAG}"
  ]
}


# -----------------------------------------------------------------------------
# Release
# -----------------------------------------------------------------------------

target "release" {
  inherits = ["image"]

  platforms = [
    "linux/amd64"
  ]

  attest = [
    "type=sbom",
    "type=provenance,mode=max"
  ]
}


# -----------------------------------------------------------------------------
# Defaults
# -----------------------------------------------------------------------------

group "default" {
  targets = ["image"]
}
