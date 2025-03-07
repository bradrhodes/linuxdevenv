#!/usr/bin/env bash
# Nerd Fonts installation

setup_fonts() {
  log_section "Installing Nerd Fonts"
  if [ -n "$NERD_FONT" ]; then
    mkdir -p ~/.fonts
    log_info "Downloading $NERD_FONT Nerd Font..."
    wget -P ~/.fonts "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/$NERD_FONT.zip"
    unzip ~/.fonts/$NERD_FONT.zip -d ~/.fonts
    rm ~/.fonts/*.zip ~/.fonts/*.md
    fc-cache -fv
    log_info "$NERD_FONT Nerd Font installed"
  else
    log_info "No Nerd Font specified, skipping font installation"
  fi
}