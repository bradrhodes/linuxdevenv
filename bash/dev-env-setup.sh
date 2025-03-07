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
source "$SCRIPT_DIR/scripts/logging.sh"

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
log_section "Setting up Nix package manager"

if ! command -v nix &> /dev/null; then
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
log_section "Installing packages via Nix"
log_info "Installing: $NIX_PACKAGES"
nix profile install $NIX_PACKAGES

# ===== UBUNTU SPECIFIC =====
log_section "Installing Ubuntu-specific packages"
if command -v apt &> /dev/null; then
  sudo apt update
  sudo apt install -y $APT_PACKAGES
else
  log_warn "apt not found. Skipping Ubuntu-specific installations."
fi

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
  log_error "Homebrew installation succeeded but it's not in PATH. Please run: eval \"\$($(find /home -name brew -type f 2>/dev/null | head -1) shellenv)\""
else
  log_success "Homebrew is properly configured in PATH"
fi

# ===== BREW PACKAGES =====
log_section "Installing packages via Homebrew"
if command -v brew &> /dev/null; then
  log_info "Installing: $BREW_PACKAGES"
  brew install $BREW_PACKAGES
else
  log_error "Homebrew not found in PATH. Installation failed or PATH not updated."
fi

# ===== FISH SHELL SETUP =====
log_section "Setting up shell environment"

if [ "$DEFAULT_SHELL" = "fish" ]; then
  if command -v fish &> /dev/null; then
    # Add fish to available shells if not already there
    if ! grep -q "$(which fish)" /etc/shells; then
      echo "$(which fish)" | sudo tee -a /etc/shells
    fi
    
    # Change default shell to fish
    sudo chsh -s "$(which fish)" "$(whoami)"
    
    # Create directories where we need to put things
    mkdir -p ~/.local/bin
    mkdir -p ~/.config/fish/conf.d/
    
    # Add ~/.local/bin to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
      export PATH="$HOME/.local/bin:$PATH"
      # Also add to profile for persistence
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
    fi
    
    # Install Starship independently (non-interactive)
    if ! command -v starship &> /dev/null; then
      log_info "Installing Starship prompt..."
      # Download and install without prompts
      curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
      log_success "Starship installed to $HOME/.local/bin"
    else
      log_info "Starship is already installed"
    fi
    
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
      
      # Set up Starship config if starship is now available
      if test -x $HOME/.local/bin/starship
        echo 'Setting up Starship config...'
        $HOME/.local/bin/starship preset $STARSHIP_PRESET > ~/.config/starship.toml
        
        # Add init to fish config if not already there
        if not grep -q 'starship init' ~/.config/fish/config.fish
          echo 'starship init fish | source' >> ~/.config/fish/config.fish
        end
      end
    "
    
    # Create Fish configuration to load Nix
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

# ===== NEOVIM SETUP =====
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

# ===== TMUX SETUP =====
log_section "Setting up TMUX"
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
log_section "Setting up Git configuration"
if command -v git &> /dev/null; then
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
log_section "Setting up SSH"
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
  log_section "Setting up GitHub SSH access"
  
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
log_section "Setting up dotfiles with chezmoi"
if command -v chezmoi &> /dev/null; then
  if [ -n "$DOTFILES_REPO" ]; then
    log_info "Initializing chezmoi with repository: $DOTFILES_REPO"
    log_debug "Repository type: $(if [[ "$DOTFILES_REPO" == git@* ]]; then echo "SSH"; else echo "HTTPS"; fi)"
    
    # Handle SSH URLs properly
    if [[ "$DOTFILES_REPO" == git@* ]]; then
      # Ensure SSH agent is running and key is added
      eval "$(ssh-agent -s)"
      ssh-add "$SSH_KEY" 2>/dev/null || true
      
      # Test SSH connection to GitHub before proceeding
      log_info "Testing SSH connection to GitHub..."
      if ! ssh -T -o StrictHostKeyChecking=no git@github.com 2>&1 | grep -q "success"; then
        log_warn "GitHub SSH connection test failed. Check your SSH setup."
        log_info "Proceeding anyway with chezmoi initialization..."
      fi
    fi
    
    # Build the init command
    CHEZMOI_CMD="chezmoi init"
    
    # Add branch if specified
    if [ -n "$DOTFILES_BRANCH" ]; then
      CHEZMOI_CMD="$CHEZMOI_CMD --branch $DOTFILES_BRANCH"
    fi
    
    # Add the repository URL
    CHEZMOI_CMD="$CHEZMOI_CMD $DOTFILES_REPO"
    
    log_debug "Running: $CHEZMOI_CMD"
    
    # Execute the init command
    if ! eval "$CHEZMOI_CMD"; then
      log_error "Failed to initialize dotfiles with chezmoi. Check your repository URL and authentication."
      log_info "To debug, try running: git clone $DOTFILES_REPO"
    else
      # Apply if specified
      if [ "$DOTFILES_APPLY" = true ]; then
        log_info "Applying dotfiles with chezmoi..."
        chezmoi apply
      fi
      
      log_success "Dotfiles successfully initialized with chezmoi"
    fi
  else
    log_info "No dotfiles repository specified (DOTFILES_REPO is empty), skipping dotfiles setup"
  fi
else
  log_error "Chezmoi not found after installation. Something went wrong."
fi

# ===== FINAL MESSAGE =====
log_section "Setup Complete"
log_success "Development environment setup complete!"
log_info "You may need to log out and log back in for all changes to take effect."
log_info "To complete Neovim setup, run: nvim"
log_info "To install TMUX plugins, press prefix + I (capital I) in a TMUX session."

# Notes about manual steps
log_warn "Remember to manually set up spacemacs if needed."