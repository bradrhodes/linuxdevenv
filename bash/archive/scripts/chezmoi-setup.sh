#!/usr/bin/env bash
# Chezmoi dotfiles setup

setup_chezmoi() {
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
}