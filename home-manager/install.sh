#!/usr/bin/env bash
# =================================================================
# Home Manager Installation Script
# =================================================================
# This script helps you install and activate Home Manager with your
# configuration for the first time.
# =================================================================

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Source Nix if it exists but isn't in PATH
if ! command -v nix &> /dev/null; then
    # Try to source Nix from common locations
    # Need to unset the guard variable to allow sourcing
    unset __ETC_PROFILE_NIX_SOURCED
    if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi
fi

# Check if running in the correct directory
if [ ! -f "flake.nix" ]; then
    log_error "flake.nix not found. Please run this script from the home-manager directory."
    exit 1
fi

log_info "Starting Home Manager installation..."

# Check for Age key (required for SOPS secrets)
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
BOOTSTRAP_NEEDED=false
MACHINE_KEY_GENERATED=false

if [ ! -f "$AGE_KEY_FILE" ]; then
    log_warn "Age key not found at $AGE_KEY_FILE"
    log_info "This appears to be a new machine. We'll set up a machine-specific key."
    BOOTSTRAP_NEEDED=true
else
    log_success "Age key found at $AGE_KEY_FILE"
fi

# Check if private.yml exists
PRIVATE_CONFIG="../bash/config/private.yml"
SOPS_CONFIG="../bash/config/.sops.yaml"
if [ ! -f "$PRIVATE_CONFIG" ]; then
    log_error "Private config not found at $PRIVATE_CONFIG"
    log_info "Initialize it with: cd ../bash && ./manage-secrets.sh init"
    exit 1
fi
log_success "Private config found at $PRIVATE_CONFIG"

# ===== BOOTSTRAP WORKFLOW FOR NEW MACHINES =====
if [ "$BOOTSTRAP_NEEDED" = true ]; then
    log_info "New Machine Setup"

    echo "This machine needs an Age key to decrypt secrets."
    echo "You'll need your master bootstrap key from 1Password."
    echo ""
    echo "If you don't have a bootstrap key yet, run: ./bootstrap-setup.sh"
    echo ""

    # Prompt for bootstrap key
    log_info "Please paste your bootstrap Age key (private key starting with AGE-SECRET-KEY-):"
    echo "Press Enter after pasting (input will be hidden)"

    BOOTSTRAP_KEY_FILE=$(mktemp)
    trap 'rm -f "$BOOTSTRAP_KEY_FILE"' EXIT INT TERM

    # Read the key (hide input)
    IFS= read -rs bootstrap_key
    echo "$bootstrap_key" > "$BOOTSTRAP_KEY_FILE"

    log_info "DEBUG: Bootstrap key file created at $BOOTSTRAP_KEY_FILE"
    log_info "DEBUG: Key starts with: $(head -c 20 "$BOOTSTRAP_KEY_FILE")..."
    log_info "DEBUG: Key length: $(wc -c < "$BOOTSTRAP_KEY_FILE") bytes"

    # Install required tools if needed
    log_info "Checking for required tools..."

    if ! command -v sops &> /dev/null || ! command -v age-keygen &> /dev/null; then
        # Need to install tools - check for Nix
        if ! command -v nix &> /dev/null; then
            log_warn "Nix is not installed. Installing Nix first..."
            curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

            # Source Nix
            unset __ETC_PROFILE_NIX_SOURCED
            if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
                . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
            fi
            log_success "Nix installed successfully"
        fi

        # No need to install - we'll use nix-shell to run tools temporarily
        log_info "Tools will be loaded temporarily via nix-shell"
    fi

    # Verify the bootstrap key can decrypt (using nix-shell for sops)
    log_info "Verifying bootstrap key..."
    log_info "DEBUG: SOPS_AGE_KEY_FILE=$BOOTSTRAP_KEY_FILE"
    log_info "DEBUG: PRIVATE_CONFIG=$PRIVATE_CONFIG"

    # Try decryption with error output
    if ! SOPS_AGE_KEY_FILE="$BOOTSTRAP_KEY_FILE" nix-shell -p sops --run "sops -d $PRIVATE_CONFIG" > /dev/null 2>&1; then
        log_error "Bootstrap key cannot decrypt private.yml"
        log_error "DEBUG: Running sops with error output:"
        SOPS_AGE_KEY_FILE="$BOOTSTRAP_KEY_FILE" nix-shell -p sops --run "sops -d $PRIVATE_CONFIG" 2>&1 | head -20
        log_info "Make sure you pasted the correct private key (starts with AGE-SECRET-KEY-)"
        exit 1
    fi
    log_success "Bootstrap key verified!"

    # Generate machine-specific key to temporary location first (using nix-shell for age)
    log_info "Generating machine-specific Age key..."
    TEMP_MACHINE_KEY="/tmp/age-machine-key-$$.tmp"
    rm -f "$TEMP_MACHINE_KEY"  # Remove if it exists from a previous run

    nix-shell -p age --run "age-keygen -o $TEMP_MACHINE_KEY" 2>&1 | tee /tmp/age-keygen-output.txt
    chmod 600 "$TEMP_MACHINE_KEY"
    log_info "DEBUG: age-keygen completed"

    # Extract the public key (case-insensitive grep)
    MACHINE_PUBLIC_KEY=$(grep -i "public key:" /tmp/age-keygen-output.txt | cut -d: -f2 | xargs)
    log_info "DEBUG: Extracted public key: $MACHINE_PUBLIC_KEY"

    if [ -z "$MACHINE_PUBLIC_KEY" ]; then
        log_error "Failed to extract public key from age-keygen output"
        log_error "Contents of /tmp/age-keygen-output.txt:"
        cat /tmp/age-keygen-output.txt
        exit 1
    fi

    rm -f /tmp/age-keygen-output.txt

    log_success "Machine key generated (temporary)"
    log_info "Machine public key: $MACHINE_PUBLIC_KEY"

    # Update .sops.yaml with the new machine key
    log_info "Adding machine key to .sops.yaml..."
    log_info "DEBUG: SOPS_CONFIG=$SOPS_CONFIG"

    # Backup
    cp "$SOPS_CONFIG" "$SOPS_CONFIG.bak"
    log_info "DEBUG: Created backup"

    # Check if key already exists
    if grep -q "$MACHINE_PUBLIC_KEY" "$SOPS_CONFIG"; then
        log_warn "Machine key already in .sops.yaml (skipping)"
    else
        log_info "DEBUG: Key not found, adding it..."
        # Read current age keys, add new one, and write back
        # The age field contains comma-separated keys
        CURRENT_KEYS=$(grep -A 10 "age: >-" "$SOPS_CONFIG" | grep "age1" | tr '\n' ' ' | sed 's/,//g')
        ALL_KEYS="$CURRENT_KEYS $MACHINE_PUBLIC_KEY"

        # Rebuild the age section
        cat > "$SOPS_CONFIG" << EOF
creation_rules:
  # Encrypt with Age key
  - path_regex: .*
    age: >-
EOF

        # Add each key on a new line with proper indentation (remove trailing comma on last key)
        KEYS_ARRAY=($ALL_KEYS)
        for i in "${!KEYS_ARRAY[@]}"; do
            if [ $i -eq $((${#KEYS_ARRAY[@]} - 1)) ]; then
                # Last key - no comma
                echo "      ${KEYS_ARRAY[$i]}" >> "$SOPS_CONFIG"
            else
                # Not last key - add comma
                echo "      ${KEYS_ARRAY[$i]}," >> "$SOPS_CONFIG"
            fi
        done

        log_success "Added machine key to .sops.yaml"
    fi

    log_info "DEBUG: About to rekey private.yml"

    # Rekey private.yml with the updated .sops.yaml
    # Need to cd to the config directory so sops can find .sops.yaml
    log_info "Re-encrypting private.yml with updated keys..."
    REKEY_DIR="$(dirname "$SOPS_CONFIG")"
    ORIGINAL_DIR_FOR_REKEY="$PWD"
    cd "$REKEY_DIR" || {
        log_error "Failed to cd to $REKEY_DIR for rekeying"
        mv "$SOPS_CONFIG.bak" "$SOPS_CONFIG"
        rm -f "$TEMP_MACHINE_KEY"
        exit 1
    }

    if ! SOPS_AGE_KEY_FILE="$BOOTSTRAP_KEY_FILE" nix-shell -p sops --run "sops updatekeys -y private.yml"; then
        log_error "Failed to rekey private.yml"
        log_warn "Restoring backup .sops.yaml"
        mv .sops.yaml.bak .sops.yaml
        cd "$ORIGINAL_DIR_FOR_REKEY"
        rm -f "$TEMP_MACHINE_KEY"
        exit 1
    fi

    cd "$ORIGINAL_DIR_FOR_REKEY"
    log_success "private.yml re-encrypted with new machine key"
    log_info "DEBUG: Rekey completed successfully"

    # Verify the new machine key can decrypt
    log_info "Verifying new machine key can decrypt..."
    log_info "DEBUG: Using temp key at: $TEMP_MACHINE_KEY"
    if ! SOPS_AGE_KEY_FILE="$TEMP_MACHINE_KEY" nix-shell -p sops --run "sops -d $PRIVATE_CONFIG" > /dev/null 2>&1; then
        log_error "New machine key cannot decrypt private.yml even after rekeying!"
        log_warn "Restoring backup .sops.yaml"
        mv "$SOPS_CONFIG.bak" "$SOPS_CONFIG"
        rm -f "$TEMP_MACHINE_KEY"
        exit 1
    fi
    log_success "New machine key verified!"
    log_info "DEBUG: Verification passed, now saving key permanently"

    # Now that everything worked, save the machine key permanently
    log_info "Saving machine key to $AGE_KEY_FILE..."
    mkdir -p "$(dirname "$AGE_KEY_FILE")"
    log_info "DEBUG: Created directory $(dirname "$AGE_KEY_FILE")"
    cp "$TEMP_MACHINE_KEY" "$AGE_KEY_FILE"
    log_info "DEBUG: Copied temp key to permanent location"
    chmod 600 "$AGE_KEY_FILE"
    rm -f "$TEMP_MACHINE_KEY"
    log_success "Machine key saved to $AGE_KEY_FILE"
    log_info "DEBUG: Key saved successfully"

    # Commit and push changes
    log_info "Committing updated .sops.yaml and private.yml to git..."
    log_info "DEBUG: Current dir: $PWD"
    ORIGINAL_DIR="$PWD"
    log_info "DEBUG: Changing to $(dirname "$SOPS_CONFIG")"
    cd "$(dirname "$SOPS_CONFIG")" || {
        log_error "Failed to cd to $(dirname "$SOPS_CONFIG")"
        exit 1
    }
    log_info "DEBUG: Changed to $(pwd)"

    if git diff --quiet .sops.yaml private.yml 2>/dev/null; then
        log_info "No changes to commit (key may already be in .sops.yaml)"
    else
        log_info "Adding files to git..."
        git add .sops.yaml private.yml || {
            log_warn "Failed to git add files, but continuing..."
        }

        HOSTNAME=$(hostname)
        log_info "Creating commit..."
        git commit -m "Add Age key for machine: $HOSTNAME

Machine public key: $MACHINE_PUBLIC_KEY

This allows this machine to decrypt the encrypted secrets.
Generated by home-manager/install.sh" || {
            log_warn "Git commit failed or nothing to commit, but continuing..."
        }

        log_info "Pushing to remote..."
        if git push; then
            log_success "Changes pushed to remote repository"
        else
            log_warn "Could not push to remote. You may need to push manually later:"
            echo "  cd bash/config && git push"
        fi
    fi

    cd "$ORIGINAL_DIR" || {
        log_error "Failed to return to original directory: $ORIGINAL_DIR"
        log_info "Current directory: $(pwd)"
        exit 1
    }

    log_info "Returned to: $(pwd)"

    # Clean up bootstrap key
    rm -f "$BOOTSTRAP_KEY_FILE"
    log_success "Bootstrap complete! Machine key is now set up."
    log_info "DEBUG: Exiting bootstrap workflow, continuing with main script"
    echo ""
fi

log_info "DEBUG: Past bootstrap workflow check"
log_info "Continuing with Home Manager installation..."

# Warn if Git credentials might not be set
log_info "Checking Git credentials in private.yml..."

# Check git credentials using nix-shell for sops
if command -v nix &> /dev/null; then
    # Check if we can decrypt the private config
    if ! SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" nix-shell -p sops --run "sops -d $PRIVATE_CONFIG" > /dev/null 2>&1; then
        log_error "Cannot decrypt $PRIVATE_CONFIG"
        echo ""
        echo "The Age key at $AGE_KEY_FILE is not authorized to decrypt private.yml"
        echo ""
        echo "To decrypt, you need the private key matching one of the public keys in:"
        echo "  bash/config/.sops.yaml"
        echo ""
        echo "Authorized public keys:"
        grep "age1" "$SOPS_CONFIG" | sed 's/,$//' | sed 's/^[[:space:]]*/  - /'
        echo ""
        echo "Options to fix this:"
        echo ""
        echo "1. If you have a bootstrap/master key from 1Password:"
        echo "   - Delete the current key: rm $AGE_KEY_FILE"
        echo "   - Re-run this script and paste the bootstrap key when prompted"
        echo ""
        echo "2. If this machine's key should be added to .sops.yaml:"
        echo "   - Your current public key is: \$(age-keygen -y $AGE_KEY_FILE)"
        echo "   - Add it to bash/config/.sops.yaml under the age: section"
        echo "   - Rekey: SOPS_AGE_KEY_FILE=<bootstrap-key> sops updatekeys bash/config/private.yml"
        echo ""
        exit 1
    fi

    # Try to check if git user name is empty
    GIT_NAME=$(SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" nix-shell -p sops --run "sops -d $PRIVATE_CONFIG" 2>/dev/null | grep -A1 "git_user:" | grep "name:" | cut -d'"' -f2)
    if [ -z "$GIT_NAME" ] || [ "$GIT_NAME" = "" ]; then
        log_warn "Git user name appears to be empty in private.yml"
        log_info "Edit it with: cd ../bash && ./manage-secrets.sh edit config/private.yml"
        log_info "Add your name and email under git_user section"
        echo ""
        echo "Press Enter to continue anyway, or Ctrl+C to abort and edit secrets first..."
        read -r
    else
        log_success "Git credentials found in private.yml"
    fi
fi

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    log_warn "Nix is not installed. Installing Nix with Determinate Systems installer..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

    # Source Nix
    unset __ETC_PROFILE_NIX_SOURCED
    if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    fi

    log_success "Nix installed successfully"
else
    log_success "Nix is already installed"
fi

# Enable flakes if not already enabled
NIX_CONF="$HOME/.config/nix/nix.conf"
if ! grep -q "experimental-features.*flakes" "$NIX_CONF" 2>/dev/null; then
    log_info "Enabling flakes..."
    mkdir -p "$(dirname "$NIX_CONF")"
    echo "experimental-features = nix-command flakes" >> "$NIX_CONF"
    log_success "Flakes enabled"
else
    log_success "Flakes already enabled"
fi

# Build and activate Home Manager configuration
log_info "Building and activating Home Manager configuration..."
nix run home-manager/master -- switch --flake .

log_success "Home Manager configuration activated!"

# Check if Fish is the default shell
FISH_PATH=$(which fish 2>/dev/null)
if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
    log_warn "Fish shell is installed but not set as your default shell."
    echo ""

    # Check if fish is in /etc/shells
    if ! grep -q "^${FISH_PATH}$" /etc/shells; then
        log_warn "Fish is not in /etc/shells. Adding it now..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
        log_success "Added $FISH_PATH to /etc/shells"
    fi

    echo "To set Fish as your default shell, run:"
    echo "  sudo chsh -s $FISH_PATH \$USER"
    echo ""
fi

log_success "Setup complete! 🎉"
echo ""
log_info "Important next steps:"
echo ""
echo "1. Set Fish as default shell (if you haven't already):"
echo "   sudo chsh -s $FISH_PATH \$USER"
echo ""
echo "2. Git Configuration:"
echo "   ✅ Your Git user.name and user.email are automatically loaded from private.yml"
if [ -z "$GIT_NAME" ] || [ "$GIT_NAME" = "" ]; then
    echo "   ⚠️  But they appear to be empty! Edit them with:"
    echo "      cd ../bash && ./manage-secrets.sh edit config/private.yml"
fi
echo ""
echo "3. Your SSH key was generated at ~/.ssh/id_ed25519"
echo "   The public key was displayed above - add it to GitHub if needed"
echo ""
echo "4. Secrets management:"
echo "   Your SOPS/Age workflow is fully integrated!"
echo "   - Edit secrets: ../bash/manage-secrets.sh edit config/private.yml"
echo "   - View secrets: ../bash/manage-secrets.sh view config/private.yml"
echo "   - See SECRETS.md for details on the integration"
echo ""
echo "5. Making changes:"
echo "   - Edit home.nix to add packages or change configs"
echo "   - Run: home-manager switch --flake ."
echo "   - Changes to private.yml are picked up automatically"
echo ""
echo "Documentation:"
echo "  - README.md - Quick reference"
echo "  - SECRETS.md - SOPS integration details"
echo "  - MIGRATION.md - Full migration guide"
echo "  - COMPARISON.md - Old vs new comparison"
echo ""
echo "Log out and log back in for all changes to take effect."
echo ""
