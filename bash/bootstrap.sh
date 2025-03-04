#!/usr/bin/env bash
# =================================================================
# Bootstrap Script for Linux Development Environment
# =================================================================
# This script checks for required tools and installs any that are
# missing. It handles essential utilities needed before the main
# environment setup can run.
# =================================================================

set -e  # Exit on error

# Source the logging module
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "$SCRIPT_DIR/logging.sh" ]; then
  source "$SCRIPT_DIR/logging.sh"
else
  # Minimal logging functions if logging.sh is not yet available
  LOG_GREEN='\033[0;32m'
  LOG_YELLOW='\033[1;33m'
  LOG_RED='\033[0;31m'
  LOG_NC='\033[0m'
  log_info() { echo -e "${LOG_GREEN}[INFO]${LOG_NC} $1"; }
  log_warn() { echo -e "${LOG_YELLOW}[WARNING]${LOG_NC} $1"; }
  log_error() { echo -e "${LOG_RED}[ERROR]${LOG_NC} $1"; return 1; }
  log_fatal() { echo -e "${LOG_RED}[FATAL]${LOG_NC} $1"; exit 1; }
  log_success() { echo -e "${LOG_GREEN}✓${LOG_NC} $1"; }
  log_failure() { echo -e "${LOG_RED}✗${LOG_NC} $1"; }
  log_section() { echo -e "\n${LOG_GREEN}===== $1 =====${LOG_NC}"; }
fi

# Required tools - these must be installed for the setup to work
REQUIRED_TOOLS=(
  "git"      # Version control
  "curl"     # For downloading files
  "unzip"    # For extracting archives
  "sops"     # Secrets management
  "yq"       # YAML processor
  "age"      # Modern encryption (replaces GPG)
)

# Optional tools - these are helpful but not strictly necessary
OPTIONAL_TOOLS=(
  "wget"     # Alternative download tool
  "vim"      # Text editor
  "nano"     # Simple text editor
  "less"     # Pager for viewing files
  "ca-certificates" # SSL certificates
)

# Package maps for tools that might have different package names
declare -A PACKAGE_MAP
PACKAGE_MAP["yq"]="yq"
PACKAGE_MAP["sops"]="sops"
PACKAGE_MAP["age"]="age"

# Manual installation details for special tools
declare -A MANUAL_INSTALL_INFO
MANUAL_INSTALL_INFO["sops,version"]="3.7.3"
MANUAL_INSTALL_INFO["sops,url"]="https://github.com/mozilla/sops/releases/download/v${MANUAL_INSTALL_INFO["sops,version"]}/sops-v${MANUAL_INSTALL_INFO["sops,version"]}.linux.ARCH"
MANUAL_INSTALL_INFO["sops,bin"]="sops"

MANUAL_INSTALL_INFO["yq,version"]="4.34.1"
MANUAL_INSTALL_INFO["yq,url"]="https://github.com/mikefarah/yq/releases/download/v${MANUAL_INSTALL_INFO["yq,version"]}/yq_linux_ARCH"
MANUAL_INSTALL_INFO["yq,bin"]="yq"

MANUAL_INSTALL_INFO["age,version"]="1.1.1"
MANUAL_INSTALL_INFO["age,url"]="https://github.com/FiloSottile/age/releases/download/v${MANUAL_INSTALL_INFO["age,version"]}/age-v${MANUAL_INSTALL_INFO["age,version"]}-linux-ARCH.tar.gz"
MANUAL_INSTALL_INFO["age,bin"]="age"

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
    log_error "No supported package manager found."
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
      log_error "You need sudo privileges to install packages."
      return 1
    fi
    log_info "Using sudo for package installation"
  else
    log_error "Neither root access nor sudo available. Cannot install packages."
    return 1
  fi
  return 0
}

# Install a tool using the most appropriate method
install_tool() {
  local tool=$1
  local package=${PACKAGE_MAP[$tool]:-$tool}
  
  log_info "Installing $tool..."
  
  # Try package manager first
  if $SUDO $PKG_INSTALL $package; then
    log_success "$tool installed successfully via package manager"
    return 0
  fi
  
  # If the package manager failed and we have manual install info, try that
  if [[ -n "${MANUAL_INSTALL_INFO[$tool,url]}" ]]; then
    log_info "Trying manual installation for $tool..."
    
    # Determine architecture
    ARCH=$(uname -m)
    case $ARCH in
      x86_64) ARCH="amd64" ;;
      aarch64|arm64) ARCH="arm64" ;;
      *) 
        log_warn "Unsupported architecture: $ARCH. Installation may fail."
        ARCH="amd64"
        ;;
    esac
    
    # Replace ARCH in the URL
    local url="${MANUAL_INSTALL_INFO[$tool,url]}"
    url="${url//ARCH/$ARCH}"
    
    local bin="${MANUAL_INSTALL_INFO[$tool,bin]}"
    
    # Download and install
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
    
    log_info "Downloading $tool from $url..."
    
    # Special handling for tarballs
    if [[ "$url" == *.tar.gz ]]; then
      if curl -s -L -o "$TEMP_DIR/$tool.tar.gz" "$url"; then
        tar -xzf "$TEMP_DIR/$tool.tar.gz" -C "$TEMP_DIR"
        
        # Find the binary in the extracted files
        BINARY_PATH=$(find "$TEMP_DIR" -type f -name "$bin*" -executable | head -n 1)
        
        if [ -n "$BINARY_PATH" ]; then
          if [ -w /usr/local/bin ]; then
            cp "$BINARY_PATH" "/usr/local/bin/$bin"
          else
            $SUDO cp "$BINARY_PATH" "/usr/local/bin/$bin"
          fi
          
          if check_cmd "$tool"; then
            log_success "$tool installed successfully via manual installation"
            return 0
          fi
        else
          log_error "Could not find $bin binary in extracted files"
        fi
      fi
    else
      # Direct binary download
      if curl -s -L -o "$TEMP_DIR/$bin" "$url"; then
        chmod +x "$TEMP_DIR/$bin"
        
        if [ -w /usr/local/bin ]; then
          mv "$TEMP_DIR/$bin" /usr/local/bin/
        else
          $SUDO mv "$TEMP_DIR/$bin" /usr/local/bin/
        fi
        
        if check_cmd "$tool"; then
          log_success "$tool installed successfully via manual installation"
          return 0
        fi
      fi
    fi
    
    log_error "Manual installation of $tool failed"
    return 1
  fi
  
  log_error "Failed to install $tool"
  return 1
}

# Main function to check and install prerequisites
bootstrap() {
  log_section "Checking Prerequisites"
  
  # Initial check of tools
  local required_missing=0
  local optional_missing=0
  
  # Check required tools
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if check_cmd "$tool"; then
      log_success "$tool is already installed"
    else
      log_info "$tool is missing, will install"
      required_missing=$((required_missing + 1))
    fi
  done
  
  # Check optional tools
  log_section "Optional Tools"
  for tool in "${OPTIONAL_TOOLS[@]}"; do
    if check_cmd "$tool"; then
      log_success "$tool is already installed"
    else
      log_info "$tool is missing, will install if possible"
      optional_missing=$((optional_missing + 1))
    fi
  done
  
  # If everything is already installed, we're done
  if [ $required_missing -eq 0 ] && [ $optional_missing -eq 0 ]; then
    log_section "Status"
    log_success "All tools are already installed!"
    log_info "You're all set! You can proceed with the setup."
    return 0
  fi
  
  # Setup package manager
  log_section "Package Manager Setup"
  if ! setup_package_manager; then
    log_error "Cannot proceed without a supported package manager."
    return 1
  fi
  
  # Setup sudo
  if ! setup_sudo; then
    log_error "Cannot proceed without proper privileges."
    return 1
  fi
  
  # Update package indexes
  log_info "Updating package indexes..."
  $SUDO $PKG_UPDATE
  
  # Install missing required tools
  if [ $required_missing -gt 0 ]; then
    log_section "Installing Required Tools"
    
    local failed=0
    for tool in "${REQUIRED_TOOLS[@]}"; do
      if ! check_cmd "$tool"; then
        if ! install_tool "$tool"; then
          failed=$((failed + 1))
        fi
      fi
    done
    
    if [ $failed -gt 0 ]; then
      log_error "$failed required tool(s) could not be installed."
      return 1
    fi
  fi
  
  # Install missing optional tools
  if [ $optional_missing -gt 0 ]; then
    log_section "Installing Optional Tools"
    
    for tool in "${OPTIONAL_TOOLS[@]}"; do
      if ! check_cmd "$tool"; then
        install_tool "$tool" || log_warn "Could not install optional tool: $tool"
      fi
    done
  fi
  
  # Final verification
  log_section "Verification"
  local missing=0
  
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if check_cmd "$tool"; then
      log_success "$tool is installed and available"
    else
      log_failure "$tool is still missing"
      missing=$((missing + 1))
    fi
  done
  
  if [ $missing -eq 0 ]; then
    log_success "All required tools are now installed!"
    return 0
  else
    log_error "$missing required tool(s) still missing."
    return 1
  fi
}

# Run the bootstrap process
if bootstrap; then
  log_section "Next Steps"
  log_success "Bootstrap completed successfully!"
  log_info "You can now proceed with:"
  log_info "  1. Initialize your private configuration: ./manage-secrets.sh init"
  log_info "  2. Run the full environment setup: ./setup.sh"
  exit 0
else
  log_section "Action Required"
  log_error "Bootstrap process could not complete successfully."
  log_info "Please install the following tools manually:"
  
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! check_cmd "$tool"; then
      log_info "  - $tool"
    fi
  done
  
  exit 1
fi