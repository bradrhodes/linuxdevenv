#!/usr/bin/env bash
# Nix package manager installation and packages setup

setup_nix() {
  # ===== NIX INSTALLATION =====
  log_section "Setting up Nix package manager"

  # Check multiple ways if Nix is installed
  if command -v nix &> /dev/null || [ -d "/nix" ] || [ -f "/nix/receipt.json" ]; then
    log_info "Nix is already installed, skipping installation..."
    
    # Ensure Nix is correctly sourced in the current shell
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    elif [ -f /etc/profile.d/nix.sh ]; then
      . /etc/profile.d/nix.sh
    fi
  else
    log_info "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    
    # Source nix
    if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    else
      log_error "Nix installation failed. Nix environment files not found."
      return 1
    fi
  fi

  # Verify nix command is available
  if ! command -v nix &> /dev/null; then
    log_warn "Nix command not found in PATH even after sourcing environment files."
    log_info "You may need to restart your shell or terminal session."
    return 0
  fi

  # ===== NIX PACKAGES =====
  log_section "Installing packages via Nix"
  log_info "Installing: $NIX_PACKAGES"
  nix profile install $NIX_PACKAGES || {
    log_warn "Some Nix packages failed to install, but continuing with setup"
  }
}