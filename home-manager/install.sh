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
    log_section "New Machine Setup"

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

    # Verify the bootstrap key can decrypt
    log_info "Verifying bootstrap key..."
    if ! SOPS_AGE_KEY_FILE="$BOOTSTRAP_KEY_FILE" sops -d "$PRIVATE_CONFIG" > /dev/null 2>&1; then
        log_error "Bootstrap key cannot decrypt private.yml"
        log_info "Make sure you pasted the correct private key (starts with AGE-SECRET-KEY-)"
        exit 1
    fi
    log_success "Bootstrap key verified!"

    # Generate machine-specific key
    log_info "Generating machine-specific Age key..."
    mkdir -p "$(dirname "$AGE_KEY_FILE")"

    if ! command -v age-keygen &> /dev/null; then
        log_error "age-keygen not found. Installing age..."
        nix profile install nixpkgs#age
    fi

    age-keygen -o "$AGE_KEY_FILE" 2>&1 | tee /tmp/age-keygen-output.txt
    chmod 600 "$AGE_KEY_FILE"
    MACHINE_KEY_GENERATED=true

    # Extract the public key
    MACHINE_PUBLIC_KEY=$(grep "public key:" /tmp/age-keygen-output.txt | cut -d: -f2 | xargs)
    rm -f /tmp/age-keygen-output.txt

    log_success "Machine key generated at $AGE_KEY_FILE"
    log_info "Machine public key: $MACHINE_PUBLIC_KEY"

    # Update .sops.yaml with the new machine key
    log_info "Adding machine key to .sops.yaml..."

    # Backup
    cp "$SOPS_CONFIG" "$SOPS_CONFIG.bak"

    # Check if key already exists
    if grep -q "$MACHINE_PUBLIC_KEY" "$SOPS_CONFIG"; then
        log_warn "Machine key already in .sops.yaml (skipping)"
    else
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

        # Add each key on a new line with proper indentation
        for key in $ALL_KEYS; do
            echo "      $key," >> "$SOPS_CONFIG"
        done

        log_success "Added machine key to .sops.yaml"
    fi

    # Rekey private.yml with the updated .sops.yaml
    log_info "Re-encrypting private.yml with updated keys..."
    if ! SOPS_AGE_KEY_FILE="$BOOTSTRAP_KEY_FILE" sops updatekeys -y "$PRIVATE_CONFIG"; then
        log_error "Failed to rekey private.yml"
        log_warn "Restoring backup .sops.yaml"
        mv "$SOPS_CONFIG.bak" "$SOPS_CONFIG"
        exit 1
    fi
    log_success "private.yml re-encrypted with new machine key"

    # Commit and push changes
    log_info "Committing updated .sops.yaml and private.yml to git..."
    cd "$(dirname "$SOPS_CONFIG")"

    if git diff --quiet .sops.yaml private.yml; then
        log_info "No changes to commit (key may already be in .sops.yaml)"
    else
        git add .sops.yaml private.yml
        HOSTNAME=$(hostname)
        git commit -m "Add Age key for machine: $HOSTNAME

Machine public key: $MACHINE_PUBLIC_KEY

This allows this machine to decrypt the encrypted secrets.
Generated by home-manager/install.sh" || true

        log_info "Pushing to remote..."
        if git push; then
            log_success "Changes pushed to remote repository"
        else
            log_warn "Could not push to remote. You may need to push manually later:"
            echo "  cd bash/config && git push"
        fi
    fi

    cd - > /dev/null

    # Clean up bootstrap key
    rm -f "$BOOTSTRAP_KEY_FILE"
    log_success "Bootstrap complete! Machine key is now set up."
    echo ""
fi

# Warn if Git credentials might not be set
log_info "Checking Git credentials in private.yml..."
if command -v sops &> /dev/null; then
    # Try to check if git user name is empty
    GIT_NAME=$(sops -d "$PRIVATE_CONFIG" 2>/dev/null | grep -A1 "git_user:" | grep "name:" | cut -d'"' -f2)
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
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source Nix
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
if [ "$SHELL" != "$(which fish 2>/dev/null)" ]; then
    log_warn "Fish shell is installed but not set as your default shell."
    echo ""
    echo "To set Fish as your default shell, run:"
    echo "  sudo chsh -s \$(which fish) \$USER"
    echo ""
fi

log_success "Setup complete! 🎉"
echo ""
log_info "Important next steps:"
echo ""
echo "1. Set Fish as default shell (if you haven't already):"
echo "   sudo chsh -s \$(which fish) \$USER"
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
