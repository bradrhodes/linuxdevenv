#!/usr/bin/env bash
# Git configuration setup script

setup_git() {
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
}