#!/usr/bin/env bash
# =================================================================
# Secret Configuration Manager
# =================================================================
# This script provides easy commands to manage your encrypted
# private configuration file with SOPS, similar to ansible-vault.
# The unencrypted file never persists on disk.
# Uses Age for encryption (simpler alternative to GPG).
# =================================================================

set -e  # Exit on error

# Source the logging module
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/scripts/logging.sh"

# Default file name - we only store the encrypted version
PRIVATE_CONFIG="$SCRIPT_DIR/config/private.yml"
PRIVATE_EXAMPLE="$SCRIPT_DIR/config/private.example.yml"

# Check if a command exists
check_cmd() {
  if command -v "$1" &> /dev/null; then
    return 0
  else
    return 1
  fi
}

# Function to edit the config file directly (primary method)
edit_config() {
  local file=${1:-$PRIVATE_CONFIG}
  
  if [ -f "$file" ]; then
    log_info "Opening encrypted file $file for editing..."
    sops "$file"
    log_success "Editing complete. Changes saved to $file"
  else
    log_info "File $file doesn't exist yet. Creating from example..."
    initialize "$file"
  fi
}

# Function to view the config without decrypting to a file
view_config() {
  local file=${1:-$PRIVATE_CONFIG}
  
  if [ ! -f "$file" ]; then
    log_fatal "File $file does not exist."
  fi
  
  log_info "Viewing encrypted file $file..."
  sops --decrypt "$file"
}

# Function to validate YAML syntax
validate_yaml() {
  local file=${1:-$PRIVATE_CONFIG}
  
  if [ ! -f "$file" ]; then
    log_fatal "File $file does not exist."
  fi
  
  if check_cmd yq; then
    log_info "Validating YAML syntax of $file..."
    if sops --decrypt "$file" | yq eval '.' - > /dev/null; then
      log_success "YAML syntax is valid."
    else
      log_error "YAML syntax is invalid. Please check your file."
    fi
  else
    log_warn "yq is not installed. Skipping YAML validation."
  fi
}

# Function to initialize from example
initialize() {
  local example_file=${PRIVATE_EXAMPLE}
  local output_file=${1:-$PRIVATE_CONFIG}
  
  # Ensure config directory exists
  mkdir -p "$(dirname "$output_file")"
  
  if [ ! -f "$example_file" ]; then
    log_fatal "Example file $example_file does not exist."
  fi
  
  if [ -f "$output_file" ]; then
    read -p "File $output_file already exists. Overwrite? (y/N) " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      log_info "Operation cancelled."
      exit 0
    fi
  fi
  
  # Create a temporary file for editing
  TEMP_FILE=$(mktemp)
  trap 'rm -f "$TEMP_FILE"' EXIT
  
  # Copy the example to the temp file
  cp "$example_file" "$TEMP_FILE"
  
  # Let the user edit the temp file with their preferred editor
  ${EDITOR:-vi} "$TEMP_FILE"
  
  log_info "Creating encrypted file from edited content..."
  sops --encrypt "$TEMP_FILE" > "$output_file"
  log_success "Encrypted file saved as $output_file"
}

# Main logic based on command line arguments
case "$1" in
  edit)
    shift
    edit_config "$@"
    ;;
  view)
    shift
    view_config "$@"
    ;;
  validate)
    shift
    validate_yaml "$@"
    ;;
  init)
    shift
    initialize "$@"
    ;;
  *)
    echo "Usage: $0 <command> [file]"
    echo
    echo "Commands:"
    echo "  edit [file]     - Edit the encrypted file (creates if it doesn't exist)"
    echo "  view [file]     - View the decrypted contents without saving to disk"
    echo "  validate [file] - Validate YAML syntax"
    echo "  init [file]     - Initialize from example file"
    echo
    echo "Default file: $PRIVATE_CONFIG"
    echo
    echo "Note: This tool never stores the unencrypted configuration on disk"
    echo "      (except temporarily during editing)"
    echo
    echo "To run the setup after managing secrets, use:"
    echo "  ./dev-env-setup.sh"
    ;;
esac