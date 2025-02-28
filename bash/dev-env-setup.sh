#!/usr/bin/env bash
# =================================================================
# Linux Development Environment Setup Script
# =================================================================
# This script sets up a complete development environment on Linux
# including Nix, Fish shell, development tools, and configurations
# for Neovim and TMUX.
# =================================================================

# ===== CONFIGURATION =====
# Load configuration from environment variables or set defaults
DOTFILES_REPO="${DOTFILES_REPO:-}"                           # Your dotfiles repository
DEFAULT_SHELL="${DEFAULT_SHELL:-fish}"                       # Options: fish, bash, zsh, etc.
INSTALL_NVCHAD="${INSTALL_NVCHAD:-true}"                     # Whether to install NvChad for Neovim
INSTALL_TMUX_PLUGINS="${INSTALL_TMUX_PLUGINS:-true}"         # Whether to install TMUX plugins
NERD_FONT="${NERD_FONT:-EnvyCodeR}"                          # Nerd Font to install
STARSHIP_PRESET="${STARSHIP_PRESET:-pastel-powerline}"       # Starship prompt preset

# Package lists
NIX_PACKAGES_DEFAULT="nixpkgs#fish nixpkgs#fzf nixpkgs#nushell nixpkgs#ncdu nixpkgs#duckdb nixpkgs#mc nixpkgs#neovim nixpkgs#git nixpkgs#chezmoi nixpkgs#ripgrep nixpkgs#bat nixpkgs#htop nixpkgs#eza nixpkgs#fontconfig nixpkgs#unzip nixpkgs#gcc nixpkgs#thefuck"
NIX_PACKAGES="${NIX_PACKAGES:-$NIX_PACKAGES_DEFAULT}"

BREW_PACKAGES_DEFAULT="uv"
BREW_PACKAGES="${BREW_PACKAGES:-$BREW_PACKAGES_DEFAULT}"

APT_PACKAGES_DEFAULT="make"
APT_PACKAGES="${APT_PACKAGES:-$APT_PACKAGES_DEFAULT}"

PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
PYTHON_TOOLS_DEFAULT="posting"
PYTHON_TOOLS="${PYTHON_TOOLS:-$PYTHON_TOOLS_DEFAULT}"

# ===== SCRIPT SETUP =====
set -e  # Exit on error
set -o pipefail  # Exit if any command in a pipe fails

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

check_cmd() {
  if command -v "$1" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Check if running as root (which we don't want)
if [ "$(id -u)" -eq 0 ]; then
  log_error "This script should not be run as root. Please run as a regular user with sudo access."
fi

# Check if sudo is available
if ! check_cmd sudo; then
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

# Display configuration
log_info "Using configuration:"
log_info "Dotfiles Repository: ${DOTFILES_REPO:-None}"
log_info "Default Shell: $DEFAULT_SHELL"
log_info "Install NvChad: $INSTALL_NVCHAD"
log_info "Install TMUX Plugins: $INSTALL_TMUX_PLUGINS"
log_info "Nerd Font: $NERD_FONT"
log_info "Starship Preset: $STARSHIP_PRESET"

# ===== NIX INSTALLATION =====
log_info "Setting up Nix package manager..."
if ! check_cmd nix; then
  log_info "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  
  # Source nix
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    log_error "Nix installation failed. File /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh not found."
  fi
else
  log_info "Nix is already installed, skipping..."
fi

# ===== NIX PACKAGES =====
log_info "Installing packages via Nix..."
log_info "Installing: $NIX_PACKAGES"
nix profile install $NIX_PACKAGES

# ===== UBUNTU SPECIFIC =====
log_info "Installing Ubuntu-specific packages..."
if check_cmd apt; then
  sudo apt update
  sudo apt install -y $APT_PACKAGES
else
  log_warn "apt not found. Skipping Ubuntu-specific installations."
fi

# ===== HOMEBREW =====
log_info "Setting up Homebrew..."
if ! check_cmd brew; then
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # Add Homebrew to PATH (this varies based on shell and platform)
  if [[ $(uname -m) == "x86_64" ]]; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.profile"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.profile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  log_info "Homebrew is already installed, skipping..."
fi

# ===== BREW PACKAGES =====
log_info "Installing packages via Homebrew..."
if check_cmd brew; then
  log_info "Installing: $BREW_PACKAGES"
  brew install $BREW_PACKAGES
else
  log_error "Homebrew not found in PATH. Installation failed or PATH not updated."
fi

# ===== PYTHON TOOLS =====
log_info "Installing Python tools..."
if check_cmd uv; then
  log_info "Installing Python tools with uv: $PYTHON_TOOLS"
  uv tool install --python $PYTHON_VERSION $PYTHON_TOOLS
else
  log_warn "uv not found. Skipping Python tools installation."
fi

# ===== FISH SHELL SETUP =====
log_info "Setting up shell environment..."

if [ "$DEFAULT_SHELL" = "fish" ]; then
  if check_cmd fish; then
    # Add fish to available shells if not already there
    if ! grep -q "$(which fish)" /etc/shells; then
      echo "$(which fish)" | sudo tee -a /etc/shells
    fi
    
    # Change default shell to fish
    sudo chsh -s "$(which fish)" "$(whoami)"
    
    # Setup Fish plugins and configuration
    fish -c "
      # Install Fisher (plugin manager) if not installed
      if not functions -q fisher
        curl -sL https://git.io/fisher | source
      end
      
      # Install/update plugins
      fisher install jorgebucaran/fisher
      fisher update
      fisher install edc/bass
      fisher install jorgebucaran/autopair.fish
      fisher install jethrokuan/z
      
      # Install Starship prompt if not installed
      if not command -s starship
        curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin/
      end
      
      # Set up Starship config
      starship preset $STARSHIP_PRESET > ~/.config/starship.toml
    "
    
    # Create Fish configuration to load Nix
    mkdir -p ~/.config/fish/conf.d/
    echo "if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
    end" > ~/.config/fish/conf.d/nix.fish
    
    log_info "Fish shell setup complete"
  else
    log_error "Fish shell not found after installation. Something went wrong."
  fi
else
  log_info "Skipping Fish shell setup as the configured default shell is: $DEFAULT_SHELL"
fi

# ===== FONTS =====
log_info "Installing Nerd Fonts..."
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

# ===== NEOVIM SETUP =====
log_info "Setting up Neovim..."
if check_cmd nvim; then
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

# ===== TMUX SETUP =====
log_info "Setting up TMUX..."
if [ "$INSTALL_TMUX_PLUGINS" = true ]; then
  if [ ! -d ~/.tmux/plugins/tpm ]; then
    mkdir -p ~/.tmux/plugins
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    
    # Create a basic tmux config if none exists
    if [ ! -f ~/.tmux.conf ]; then
      PREFIX="${TMUX_PREFIX:-C-a}"
      cat > ~/.tmux.conf << EOF
# Set prefix to $PREFIX
unbind C-b
set -g prefix $PREFIX
bind $PREFIX send-prefix

# Enable mouse mode
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF
    fi
    log_info "TMUX Plugin Manager installed"
  else
    log_info "TMUX Plugin Manager already installed"
  fi
else
  log_info "Skipping TMUX plugin setup as configured"
fi

# ===== GIT CONFIGURATION =====
log_info "Setting up Git configuration..."
if check_cmd git; then
  # Configure Git user information if provided
  if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    log_info "Git user name set to: $GIT_USER_NAME"
  fi
  
  if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    log_info "Git user email set to: $GIT_USER_EMAIL"
  fi
  
  if [ -n "$GIT_SIGNING_KEY" ]; then
    git config --global user.signingkey "$GIT_SIGNING_KEY"
    git config --global commit.gpgsign true
    log_info "Git commit signing enabled with key: $GIT_SIGNING_KEY"
  fi
else
  log_error "Git not found after installation. Something went wrong."
fi

# ===== SSH CONFIGURATION =====
log_info "Setting up SSH..."
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_${SSH_KEY_TYPE:-ed25519}"

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key if specified and it doesn't exist
if [ "$SSH_GENERATE_KEY" = true ] && [ ! -f "$SSH_KEY" ]; then
  log_info "Generating new SSH key..."
  
  # Check if we need to use a passphrase
  if [ -n "$SSH_KEY_PASSPHRASE" ]; then
    # Create a temporary file for the passphrase
    PASSPHRASE_FILE=$(mktemp)
    echo "$SSH_KEY_PASSPHRASE" > "$PASSPHRASE_FILE"
    
    # Generate the key with passphrase
    ssh-keygen -t "${SSH_KEY_TYPE:-ed25519}" -C "${SSH_KEY_EMAIL:-$GIT_USER_EMAIL}" -f "$SSH_KEY" -N "$(cat $PASSPHRASE_FILE)"
    
    # Remove the temporary file
    rm "$PASSPHRASE_FILE"
  else
    # Generate without passphrase
    ssh-keygen -t "${SSH_KEY_TYPE:-ed25519}" -C "${SSH_KEY_EMAIL:-$GIT_USER_EMAIL}" -f "$SSH_KEY" -N ""
  fi
  
  log_info "SSH key generated at: $SSH_KEY"
  
  # Start the SSH agent
  eval "$(ssh-agent -s)"
  
  # Add the key to the agent
  if [ -n "$SSH_KEY_PASSPHRASE" ]; then
    # Create a temporary file for the passphrase
    PASSPHRASE_FILE=$(mktemp)
    echo "$SSH_KEY_PASSPHRASE" > "$PASSPHRASE_FILE"
    
    # Add with passphrase
    SSH_ASKPASS="$PASSPHRASE_FILE" ssh-add "$SSH_KEY" < /dev/null
    
    # Remove the temporary file
    rm "$PASSPHRASE_FILE"
  else
    # Add without passphrase
    ssh-add "$SSH_KEY"
  fi
  
  log_info "SSH key added to agent"
else
  log_info "Using existing SSH key or SSH key generation disabled"
fi

# ===== GITHUB CONFIGURATION =====
if [ "$GITHUB_UPLOAD_KEY" = true ] && [ -f "$SSH_KEY.pub" ]; then
  log_info "Setting up GitHub SSH access..."
  
  if [ -n "$GITHUB_ACCESS_TOKEN" ] && [ -n "$GITHUB_USERNAME" ]; then
    log_info "Uploading SSH key to GitHub..."
    
    # Create a unique key title
    KEY_TITLE="$(hostname)-$(date +%Y-%m-%d)"
    
    # Get the public key
    PUBLIC_KEY=$(cat "$SSH_KEY.pub")
    
    # Create a JSON payload for the GitHub API
    JSON_PAYLOAD=$(mktemp)
    cat > "$JSON_PAYLOAD" << EOF
{
  "title": "$KEY_TITLE",
  "key": "$PUBLIC_KEY"
}
EOF
    
    # Upload the key using the GitHub API
    RESPONSE=$(curl -s -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
      -d @"$JSON_PAYLOAD" \
      "https://api.github.com/user/keys")
    
    # Remove the temporary file
    rm "$JSON_PAYLOAD"
    
    # Check if the request was successful
    if echo "$RESPONSE" | grep -q "key_id"; then
      log_info "SSH key uploaded to GitHub successfully"
    else
      log_error "Failed to upload SSH key to GitHub: $RESPONSE"
    fi
    
    # Test the SSH connection to GitHub
    log_info "Testing GitHub SSH connection..."
    ssh -T -o StrictHostKeyChecking=no git@github.com || true
  else
    log_warn "GitHub access token and/or username not provided, skipping GitHub SSH key upload"
    log_info "To manually add your SSH key to GitHub:"
    log_info "1. Copy the key: cat $SSH_KEY.pub"
    log_info "2. Go to https://github.com/settings/keys"
    log_info "3. Click 'New SSH key' and paste your key"
  fi
else
  log_info "GitHub SSH key upload disabled or SSH key not found"
fi

# ===== CHEZMOI DOTFILES =====
log_info "Setting up dotfiles with chezmoi..."
if check_cmd chezmoi; then
  if [ -n "$DOTFILES_REPO" ]; then
    log_info "Initializing chezmoi with repository: $DOTFILES_REPO"
    
    # Build the init command
    CHEZMOI_CMD="chezmoi init"
    
    # Add branch if specified
    if [ -n "$DOTFILES_BRANCH" ]; then
      CHEZMOI_CMD="$CHEZMOI_CMD --branch $DOTFILES_BRANCH"
    fi
    
    # Add the repository URL
    CHEZMOI_CMD="$CHEZMOI_CMD $DOTFILES_REPO"
    
    # Execute the init command
    eval "$CHEZMOI_CMD"
    
    # Apply if specified
    if [ "$DOTFILES_APPLY" = true ]; then
      log_info "Applying dotfiles with chezmoi..."
      chezmoi apply
    fi
    
    # Check if initialization was successful
    if [ $? -eq 0 ]; then
      log_info "Dotfiles successfully initialized with chezmoi"
    else
      log_error "Failed to initialize dotfiles with chezmoi"
    fi
  else
    log_info "No dotfiles repository specified, skipping dotfiles setup"
  fi
else
  log_error "Chezmoi not found after installation. Something went wrong."
fi

# ===== FINAL MESSAGE =====
log_info "Development environment setup complete!"
log_info "You may need to log out and log back in for all changes to take effect."
log_info "To complete Neovim setup, run: nvim"
log_info "To install TMUX plugins, press prefix + I (capital I) in a TMUX session."

# Notes about manual steps
log_warn "Remember to manually set up spacemacs if needed."