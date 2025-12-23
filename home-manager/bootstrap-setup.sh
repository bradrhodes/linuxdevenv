#!/usr/bin/env bash
# =================================================================
# Bootstrap Master Key Setup
# =================================================================
# Run this ONCE to generate your master bootstrap Age key.
# Store the private key in 1Password for use on new machines.
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

log_section() {
    echo ""
    echo -e "${GREEN}===== $1 =====${NC}"
    echo ""
}

# Check if age-keygen is available
if ! command -v age-keygen &> /dev/null; then
    log_error "age-keygen not found. Please install age first:"
    echo "  On Nix: nix profile install nixpkgs#age"
    echo "  Or use your distro package manager"
    exit 1
fi

log_section "Bootstrap Master Key Setup"

echo "This script will generate a master Age key for bootstrapping new machines."
echo "You should run this ONCE and store the key securely in 1Password."
echo ""
log_warn "If you already have a master key, press Ctrl+C now!"
echo ""
read -p "Press Enter to continue..."

# Generate the key
TEMP_KEY=$(mktemp)
log_info "Generating master bootstrap key..."

age-keygen -o "$TEMP_KEY" 2>&1 | tee /dev/tty

# Extract keys
PRIVATE_KEY=$(cat "$TEMP_KEY")
PUBLIC_KEY=$(grep "public key:" "$TEMP_KEY" | cut -d: -f2 | xargs)

log_success "Master key generated!"
echo ""

log_section "Next Steps"

echo "1. Store this PRIVATE KEY in 1Password (or your password manager):"
echo "   Title: SOPS Bootstrap Key"
echo "   Content:"
echo "   ----------------------------------------"
cat "$TEMP_KEY"
echo "   ----------------------------------------"
echo ""

echo "2. Add this PUBLIC KEY to .sops.yaml:"
echo "   Public key: $PUBLIC_KEY"
echo ""

# Offer to update .sops.yaml
SOPS_CONFIG="../bash/config/.sops.yaml"
if [ -f "$SOPS_CONFIG" ]; then
    read -p "Would you like to add this key to $SOPS_CONFIG now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check if key is already in the file
        if grep -q "$PUBLIC_KEY" "$SOPS_CONFIG"; then
            log_warn "This public key is already in .sops.yaml"
        else
            log_info "Adding public key to .sops.yaml..."

            # Backup the original
            cp "$SOPS_CONFIG" "$SOPS_CONFIG.bak"

            # Add the key (assuming YAML structure with creation_rules)
            # This is a simple append - you may need to adjust based on your .sops.yaml structure
            cat >> "$SOPS_CONFIG" << EOF

# Bootstrap master key (store private key in 1Password)
# age: $PUBLIC_KEY
EOF

            log_success "Added to .sops.yaml"
            log_info "You'll need to rekey your private.yml:"
            echo "  cd ../bash && ./manage-secrets.sh reencrypt"
        fi
    fi
else
    log_warn ".sops.yaml not found at $SOPS_CONFIG"
    echo "You'll need to manually add the public key to your .sops.yaml"
fi

# Clean up
rm "$TEMP_KEY"

echo ""
log_success "Bootstrap key setup complete!"
echo ""
log_warn "IMPORTANT: Save the private key shown above in 1Password before closing this terminal!"
echo ""
