#!/usr/bin/env bash
# Linux distribution-specific package installation

setup_linux_packages() {
  log_section "Installing system packages"
  
  # Check if a command exists
  check_cmd() {
    if command -v "$1" &> /dev/null; then
      return 0
    else
      return 1
    fi
  }

  # Setup package manager variables
  setup_package_manager() {
    if check_cmd apt-get; then
      PKG_MANAGER="apt-get"
      PKG_INSTALL="apt-get install -y"
      PKG_UPDATE="apt-get update"
      log_info "Detected package manager: apt-get (Debian/Ubuntu)"
      return 0
    elif check_cmd dnf; then
      PKG_MANAGER="dnf"
      PKG_INSTALL="dnf install -y"
      PKG_UPDATE="dnf check-update || true"
      log_info "Detected package manager: dnf (Fedora/RHEL)"
      return 0
    elif check_cmd yum; then
      PKG_MANAGER="yum"
      PKG_INSTALL="yum install -y"
      PKG_UPDATE="yum check-update || true"
      log_info "Detected package manager: yum (CentOS/RHEL)"
      return 0
    elif check_cmd pacman; then
      PKG_MANAGER="pacman"
      PKG_INSTALL="pacman -S --noconfirm"
      PKG_UPDATE="pacman -Sy"
      log_info "Detected package manager: pacman (Arch Linux)"
      return 0
    elif check_cmd zypper; then
      PKG_MANAGER="zypper"
      PKG_INSTALL="zypper install -y"
      PKG_UPDATE="zypper refresh"
      log_info "Detected package manager: zypper (openSUSE)"
      return 0
    elif check_cmd brew; then
      PKG_MANAGER="brew"
      PKG_INSTALL="brew install"
      PKG_UPDATE="brew update"
      log_info "Detected package manager: brew (Homebrew)"
      return 0
    else
      log_warn "No supported package manager found."
      return 1
    fi
  }

  # Setup sudo if needed
  setup_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
      SUDO=""
      log_info "Running as root, no sudo needed"
    elif check_cmd sudo; then
      SUDO="sudo"
      # Verify sudo access
      if ! sudo -v; then
        log_warn "You need sudo privileges to install packages."
        return 1
      fi
      log_info "Using sudo for package installation"
    else
      log_warn "Neither root access nor sudo available. Cannot install packages."
      return 1
    fi
    return 0
  }

  # Install each package individually for better error handling
  install_packages() {
    local packages=($APT_PACKAGES)
    local failed=0
    local installed=0
    
    for package in "${packages[@]}"; do
      log_info "Installing $package..."
      if $SUDO $PKG_INSTALL $package; then
        log_success "$package installed successfully"
        installed=$((installed + 1))
      else
        log_warn "Failed to install $package"
        failed=$((failed + 1))
      fi
    done
    
    log_info "$installed packages installed successfully, $failed packages failed to install"
    
    if [ $failed -eq 0 ]; then
      return 0
    else
      return 1
    fi
  }
  
  # Setup package manager
  if ! setup_package_manager; then
    log_warn "Cannot proceed without a supported package manager."
    return 1
  fi
  
  # Setup sudo
  if ! setup_sudo; then
    log_warn "Cannot proceed without proper privileges."
    return 1
  fi
  
  # Update package indexes
  log_info "Updating package indexes..."
  $SUDO $PKG_UPDATE
  
  # Install packages
  log_info "Installing packages: $APT_PACKAGES"
  if [ -z "$APT_PACKAGES" ]; then
    log_info "No packages specified, skipping installation"
    return 0
  fi
  
  # Try installing all packages at once first
  if $SUDO $PKG_INSTALL $APT_PACKAGES; then
    log_success "All packages installed successfully"
  else
    log_warn "Bulk package installation failed, trying packages individually..."
    install_packages
  fi
}