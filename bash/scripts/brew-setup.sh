#!/usr/bin/env bash
# Homebrew installation and packages setup

setup_homebrew() {
  # ===== HOMEBREW =====
  log_section "Setting up Homebrew"
  if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log_info "Homebrew is already installed"
  fi

  # Always ensure Homebrew is in PATH
  if [[ $(uname -m) == "x86_64" ]]; then
    # For Intel processors
    if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
      log_info "Adding Homebrew to PATH..."
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      # Add to profile for persistence if not already there
      if ! grep -q "brew shellenv" "$HOME/.profile"; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
        log_info "Added Homebrew to ~/.profile for persistence"
      fi
    fi
  else
    # For Apple Silicon/ARM processors
    if [ -f /opt/homebrew/bin/brew ]; then
      log_info "Adding Homebrew to PATH..."
      eval "$(/opt/homebrew/bin/brew shellenv)"
      # Add to profile for persistence if not already there
      if ! grep -q "brew shellenv" "$HOME/.profile"; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.profile" 
        log_info "Added Homebrew to ~/.profile for persistence"
      fi
    fi
  fi

  # Verify Homebrew is in PATH now
  if ! command -v brew &> /dev/null; then
    log_warn "Homebrew installation succeeded but it's not in PATH. Attempting to find and use it anyway..."
    BREW_PATH=$(find /home -name brew -type f 2>/dev/null | head -1 || find /opt -name brew -type f 2>/dev/null | head -1)
    if [ -n "$BREW_PATH" ]; then
      log_info "Found Homebrew at $BREW_PATH"
      eval "$($BREW_PATH shellenv)"
    else
      log_error "Cannot find Homebrew executable. Please run: source ~/.profile and try again"
      return 1
    fi
  else
    log_success "Homebrew is properly configured in PATH"
  fi

  # ===== BREW PACKAGES =====
  log_section "Installing packages via Homebrew"
  if command -v brew &> /dev/null; then
    # Check if BREW_PACKAGES is set and not empty
    if [ -z "$BREW_PACKAGES" ]; then
      log_info "No Homebrew packages specified, skipping installation"
      return 0
    fi
    
    log_info "Installing: $BREW_PACKAGES"
    
    # Convert the space-separated string to an array
    read -ra packages <<< "$BREW_PACKAGES"
    
    # Install packages individually for better error handling
    for package in "${packages[@]}"; do
      log_info "Installing $package..."
      if brew install "$package"; then
        log_success "$package installed successfully"
      else
        log_warn "Failed to install $package, continuing..."
      fi
    done
  else
    log_warn "Homebrew not found in PATH. Package installation skipped."
    # Return 0 to continue the script instead of exiting
    return 0
  fi
}