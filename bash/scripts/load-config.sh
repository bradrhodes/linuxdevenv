#!/usr/bin/env bash
# =================================================================
# Configuration Loader for Linux Dev Environment Setup
# =================================================================
# This script loads configuration from public and private YAML files
# and exports variables for use in the main setup script.
# =================================================================

# Source the logging module
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." &> /dev/null && pwd )"
source "$SCRIPT_DIR/logging.sh"

# Default config file locations
PUBLIC_CONFIG="$ROOT_DIR/config/public.yml"
PRIVATE_CONFIG="$ROOT_DIR/config/private.yml"
SOPS_ENABLED=false

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --public)
      PUBLIC_CONFIG="$2"
      shift 2
      ;;
    --private)
      PRIVATE_CONFIG="$2"
      shift 2
      ;;
    --sops)
      SOPS_ENABLED=true
      shift
      ;;
    *)
      log_error "Unknown option: $1"
      log_info "Usage: $0 [--public PUBLIC_CONFIG] [--private PRIVATE_CONFIG] [--sops]"
      exit 1
      ;;
  esac
done

# Check if the public config file exists
if [ ! -f "$PUBLIC_CONFIG" ]; then
  log_fatal "Public configuration file $PUBLIC_CONFIG not found."
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
  log_fatal "yq is required but not installed.\nPlease install it with: 'nix profile install nixpkgs#yq' or 'brew install yq'"
fi

# Load SOPS if enabled
if [ "$SOPS_ENABLED" = true ]; then
  if ! command -v sops &> /dev/null; then
    log_fatal "sops is required for decryption but not installed.\nPlease install it with: 'nix profile install nixpkgs#sops' or 'brew install sops'"
  fi
  
  # Create a temporary file for the decrypted content
  TEMP_PRIVATE_CONFIG=$(mktemp)
  trap 'rm -f "$TEMP_PRIVATE_CONFIG"' EXIT
  
  # Decrypt the private config
  log_info "Decrypting private configuration with SOPS..."
  sops --decrypt "$PRIVATE_CONFIG" > "$TEMP_PRIVATE_CONFIG"
  PRIVATE_CONFIG="$TEMP_PRIVATE_CONFIG"
fi

# Check if the private config file exists (after potential decryption)
if [ ! -f "$PRIVATE_CONFIG" ]; then
  log_fatal "Private configuration file $PRIVATE_CONFIG not found."
fi

# Load configuration into variables
log_section "Loading Configuration"
log_info "Loading configuration from $PUBLIC_CONFIG and $PRIVATE_CONFIG..."

# Core configuration from public config
export DEFAULT_SHELL=$(yq '.default_shell' "$PUBLIC_CONFIG")
export INSTALL_NVCHAD=$(yq '.install_nvchad' "$PUBLIC_CONFIG")
export INSTALL_TMUX_PLUGINS=$(yq '.install_tmux_plugins' "$PUBLIC_CONFIG")
export NERD_FONT=$(yq '.nerd_font' "$PUBLIC_CONFIG")
export STARSHIP_PRESET=$(yq '.starship_preset' "$PUBLIC_CONFIG")

# Package lists from public config
export NIX_PACKAGES=$(yq '.nix_packages | join(" ")' "$PUBLIC_CONFIG")
export BREW_PACKAGES=$(yq '.brew_packages | join(" ")' "$PUBLIC_CONFIG")
export FISH_PLUGINS=$(yq '.fish_plugins | join(" ")' "$PUBLIC_CONFIG")
export APT_PACKAGES=$(yq '.apt_packages | join(" ")' "$PUBLIC_CONFIG")

# Additional configuration from public config
export PYTHON_VERSION=$(yq '.python_version' "$PUBLIC_CONFIG")
export PYTHON_TOOLS=$(yq '.python_tools | join(" ")' "$PUBLIC_CONFIG")
export TMUX_PREFIX=$(yq '.tmux_prefix' "$PUBLIC_CONFIG")
export TMUX_PLUGINS=$(yq '.tmux_plugins | join(" ")' "$PUBLIC_CONFIG")

# Load logging configuration
log_level_value=$(yq '.log_level // "info"' "$PUBLIC_CONFIG")
case "$log_level_value" in
  debug)
    export LOG_LEVEL=0
    ;;
  info)
    export LOG_LEVEL=1
    ;;
  warn|warning)
    export LOG_LEVEL=2
    ;;
  error)
    export LOG_LEVEL=3
    ;;
  *)
    log_warn "Unknown log level in config: $log_level_value, using 'info'"
    export LOG_LEVEL=1
    ;;
esac

log_debug "Log level set to: $log_level_value ($LOG_LEVEL)"

# Git configuration from private config
export GIT_USER_NAME=$(yq '.git_user.name' "$PRIVATE_CONFIG")
export GIT_USER_EMAIL=$(yq '.git_user.email' "$PRIVATE_CONFIG")
export GIT_SIGNING_KEY=$(yq '.git_user.signing_key' "$PRIVATE_CONFIG")

# SSH configuration from private config
export SSH_GENERATE_KEY=$(yq '.ssh.generate_key' "$PRIVATE_CONFIG")
export SSH_KEY_TYPE=$(yq '.ssh.key_type' "$PRIVATE_CONFIG")
export SSH_KEY_EMAIL=$(yq '.ssh.key_email' "$PRIVATE_CONFIG")
export SSH_KEY_PASSPHRASE=$(yq '.ssh.key_passphrase' "$PRIVATE_CONFIG")

# GitHub configuration from private config
export GITHUB_USERNAME=$(yq '.github.username' "$PRIVATE_CONFIG")
export GITHUB_UPLOAD_KEY=$(yq '.github.upload_key' "$PRIVATE_CONFIG")
export GITHUB_ACCESS_TOKEN=$(yq '.github.access_token' "$PRIVATE_CONFIG")

# Dotfiles configuration from private config
export DOTFILES_REPO=$(yq '.dotfiles.repo' "$PRIVATE_CONFIG")
export DOTFILES_BRANCH=$(yq '.dotfiles.branch' "$PRIVATE_CONFIG")
export DOTFILES_APPLY=$(yq '.dotfiles.apply' "$PRIVATE_CONFIG")

# Load tokens if they exist
export NPM_TOKEN=$(yq '.tokens.npm // ""' "$PRIVATE_CONFIG")
export AWS_ACCESS_KEY=$(yq '.tokens.aws_access_key // ""' "$PRIVATE_CONFIG")
export AWS_SECRET_KEY=$(yq '.tokens.aws_secret_key // ""' "$PRIVATE_CONFIG")

log_success "Configuration loaded successfully"
log_info "Run the setup script with: source $SCRIPT_DIR/load-config.sh && ./dev-env-setup.sh"