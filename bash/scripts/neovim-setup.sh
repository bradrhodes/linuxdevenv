#!/usr/bin/env bash
# Neovim setup with optional NvChad

setup_neovim() {
  log_section "Setting up Neovim"
  if command -v nvim &> /dev/null; then
    if [ "$INSTALL_NVCHAD" = true ]; then
      # Using NvChad
      if [ ! -d ~/.config/nvim ]; then
        git clone https://github.com/NvChad/starter ~/.config/nvim
        log_info "NvChad installed. Run nvim to complete setup."
      else
        log_warn "Neovim config directory already exists. Skipping NvChad installation."
      fi
    else
      log_info "Skipping NvChad installation as configured"
    fi
  else
    log_error "Neovim not found after installation. Something went wrong."
  fi
}