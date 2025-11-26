#!/usr/bin/env bash
# Fish shell and related tools setup

setup_fish_shell() {
  log_section "Setting up shell environment"

  if [ "$DEFAULT_SHELL" = "fish" ]; then
    # Try to find fish - check common Nix locations if not in PATH
    fish_path=""
    if command -v fish &> /dev/null; then
      fish_path=$(which fish)
    elif [ -f "$HOME/.nix-profile/bin/fish" ]; then
      fish_path="$HOME/.nix-profile/bin/fish"
    elif [ -f "/nix/var/nix/profiles/default/bin/fish" ]; then
      fish_path="/nix/var/nix/profiles/default/bin/fish"
    fi
    
    if [ -n "$fish_path" ]; then
      # Add fish to available shells if not already there
      if ! grep -q "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells
      fi
      
      # Change default shell to fish
      sudo chsh -s "$fish_path" "$(whoami)"
      
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
      "$fish_path" -c "
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
}