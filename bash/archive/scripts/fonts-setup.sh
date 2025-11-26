#!/usr/bin/env bash
# Nerd Fonts installation

setup_fonts() {
  log_section "Installing Nerd Fonts"
  if [ -n "$NERD_FONT" ]; then
    # Remove quotes from font name if present
    local font_name
    font_name=$(echo "$NERD_FONT" | tr -d '"')
    
    mkdir -p ~/.fonts
    log_info "Downloading $font_name Nerd Font..."
    wget -P ~/.fonts "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/${font_name}.zip"
    
    if [ -f ~/.fonts/${font_name}.zip ]; then
      unzip ~/.fonts/${font_name}.zip -d ~/.fonts
      rm ~/.fonts/*.zip ~/.fonts/*.md 2>/dev/null || true
      fc-cache -fv
      log_success "$font_name Nerd Font installed"
    else
      log_warn "Failed to download $font_name Nerd Font"
    fi
  else
    log_info "No Nerd Font specified, skipping font installation"
  fi
}