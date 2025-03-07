#!/usr/bin/env bash
# =================================================================
# SSH Configuration Setup
# =================================================================

# Function to set up SSH
setup_ssh() {
  log_section "Setting up SSH"
  local ssh_dir="$HOME/.ssh"
  local ssh_key="$ssh_dir/id_${SSH_KEY_TYPE:-ed25519}"

  # Create SSH directory if it doesn't exist
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  # Generate SSH key if specified and it doesn't exist
  if [ "$SSH_GENERATE_KEY" = true ]; then
    if [ ! -f "$ssh_key" ]; then
      log_info "Generating new SSH key..."
      
      # Check if we need to use a passphrase
      if [ -n "$SSH_KEY_PASSPHRASE" ]; then
        # Create a temporary file for the passphrase
        local passphrase_file=$(mktemp)
        echo "$SSH_KEY_PASSPHRASE" > "$passphrase_file"
        
        # Generate the key with passphrase
        ssh-keygen -t "${SSH_KEY_TYPE:-ed25519}" -C "${SSH_KEY_EMAIL:-$GIT_USER_EMAIL}" -f "$ssh_key" -N "$(cat $passphrase_file)"
        
        # Remove the temporary file
        rm "$passphrase_file"
      else
        # Generate without passphrase
        ssh-keygen -t "${SSH_KEY_TYPE:-ed25519}" -C "${SSH_KEY_EMAIL:-$GIT_USER_EMAIL}" -f "$ssh_key" -N ""
      fi
      
      log_info "SSH key generated at: $ssh_key"
    else
      log_info "SSH key already exists at $ssh_key, skipping generation"
    fi
    
    # Start the SSH agent
    eval "$(ssh-agent -s)"
    
    # Add the key to the agent
    if [ -n "$SSH_KEY_PASSPHRASE" ]; then
      # Create a temporary file for the passphrase
      local passphrase_file=$(mktemp)
      echo "$SSH_KEY_PASSPHRASE" > "$passphrase_file"
      
      # Add with passphrase
      SSH_ASKPASS="$passphrase_file" ssh-add "$ssh_key" < /dev/null
      
      # Remove the temporary file
      rm "$passphrase_file"
    else
      # Add without passphrase
      ssh-add "$ssh_key"
    fi
    
    log_info "SSH key added to agent"
  else
    log_info "SSH key generation disabled"
  fi
}