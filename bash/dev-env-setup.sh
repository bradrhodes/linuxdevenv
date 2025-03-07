#!/usr/bin/env bash
# =================================================================
# Linux Development Environment Setup Script
# =================================================================
# This script sets up a complete development environment on Linux
# including Nix, Fish shell, development tools, and configurations
# for Neovim and TMUX.
# It automatically loads and decrypts configuration.
# =================================================================

set -e  # Exit on error
set -o pipefail  # Exit if any command in a pipe fails

# Source the logging module
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Extend sudo timeout for the duration of the script
extend_sudo_timeout() {
  # Check if sudo is available
  if command -v sudo &> /dev/null; then
    echo "This script requires sudo privileges for some operations."
    echo "You will be prompted for your password once at the beginning."
    echo "Sudo access will be maintained throughout the script."
    
    # Request sudo privileges and keep them alive
    sudo -v
    
    # Keep sudo privileges alive in the background
    (while true; do sudo -v; sleep 60; done) &
    SUDO_KEEPALIVE_PID=$!
    
    # Trap to kill the sudo keep-alive process when the script exits
    trap 'kill $SUDO_KEEPALIVE_PID' EXIT
  fi
}

# Initialize sudo privileges at the beginning
extend_sudo_timeout

source "$SCRIPT_DIR/scripts/logging.sh"
source "$SCRIPT_DIR/scripts/ssh-setup.sh"
source "$SCRIPT_DIR/scripts/github-setup.sh"
source "$SCRIPT_DIR/scripts/git-setup.sh"
source "$SCRIPT_DIR/scripts/nix-setup.sh"
source "$SCRIPT_DIR/scripts/fish-setup.sh"
source "$SCRIPT_DIR/scripts/fonts-setup.sh"
source "$SCRIPT_DIR/scripts/neovim-setup.sh"
source "$SCRIPT_DIR/scripts/tmux-setup.sh"
source "$SCRIPT_DIR/scripts/chezmoi-setup.sh"
source "$SCRIPT_DIR/scripts/brew-setup.sh"
source "$SCRIPT_DIR/scripts/linux-package-manager-setup.sh"

# Configuration files
PUBLIC_CONFIG="$SCRIPT_DIR/config/public.yml"
PRIVATE_CONFIG="$SCRIPT_DIR/config/private.yml"

# Check if files exist
if [ ! -f "$PUBLIC_CONFIG" ]; then
  log_fatal "Public configuration file $PUBLIC_CONFIG not found."
fi

if [ ! -f "$PRIVATE_CONFIG" ]; then
  log_fatal "Encrypted private configuration file $PRIVATE_CONFIG not found.
Please run './manage-secrets.sh init' to create one."
fi

# Load the configuration with SOPS decryption
log_section "Loading Configuration"
log_info "Loading configuration with SOPS decryption..."

if ! source "$SCRIPT_DIR/scripts/load-config.sh" --public "$PUBLIC_CONFIG" --private "$PRIVATE_CONFIG" --sops; then
  log_fatal "Failed to load configuration."
fi

log_success "Configuration loaded successfully"

# ===== SCRIPT SETUP =====
# Display loaded configuration
log_section "Starting Development Environment Setup"
log_info "Using configuration:"
log_info "Default Shell: $DEFAULT_SHELL"
log_info "Install NvChad: $INSTALL_NVCHAD"
log_info "Install TMUX Plugins: $INSTALL_TMUX_PLUGINS"
log_info "Nerd Font: $NERD_FONT"
log_info "Starship Preset: $STARSHIP_PRESET"

# Check if running as root (which we don't want)
if [ "$(id -u)" -eq 0 ]; then
  log_error "This script should not be run as root. Please run as a regular user with sudo access."
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
  log_error "sudo is required but not installed. Please install sudo first."
fi

# Make sure we're on a supported system
if [ -f /etc/os-release ]; then
  . /etc/os-release
  if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"ubuntu"* && "$ID_LIKE" != *"debian"* ]]; then
    log_warn "This script is optimized for Ubuntu/Debian. Some parts may not work correctly on $PRETTY_NAME."
  fi
else
  log_warn "Unable to detect OS. This script is optimized for Ubuntu/Debian."
fi

# ===== NIX INSTALLATION =====
# Install NIX and NIX packages
setup_nix

# ===== UBUNTU SPECIFIC =====
setup_linux_packages

# ===== HOMEBREW =====
setup_homebrew

# ===== FISH SHELL SETUP =====
setup_fish_shell

# ===== FONTS =====
setup_fonts

# ===== NEOVIM SETUP =====
setup_neovim

# ===== TMUX SETUP =====
setup_tmux

# ===== GIT CONFIGURATION =====
setup_git

# ===== SSH CONFIGURATION =====
setup_ssh

# ===== GITHUB CONFIGURATION =====
setup_github

# ===== CHEZMOI DOTFILES =====
setup_chezmoi

# ===== FINAL MESSAGE =====
log_section "Setup Complete"
log_success "Development environment setup complete!"
log_info "You may need to log out and log back in for all changes to take effect."
log_info "To complete Neovim setup, run: nvim"
log_info "To install TMUX plugins, press prefix + I (capital I) in a TMUX session."

# Notes about manual steps
log_warn "Remember to manually set up spacemacs if needed."