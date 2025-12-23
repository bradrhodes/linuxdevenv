{ config, pkgs, ... }:

{
  # ===== ACTIVATION SCRIPTS =====
  # These run during home-manager switch for things that need custom setup
  home.activation = {
    # Install LazyVim configuration
    installLazyVim = config.lib.dag.entryAfter ["writeBoundary"] ''
      NVIM_CONFIG="$HOME/.config/nvim"
      if [ ! -d "$NVIM_CONFIG" ]; then
        $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/LazyVim/starter "$NVIM_CONFIG"
        echo "LazyVim installed to $NVIM_CONFIG"
      else
        echo "LazyVim config already exists at $NVIM_CONFIG"
      fi
    '';

    # Install Nerd Font (EnvyCodeR)
    installNerdFont = config.lib.dag.entryAfter ["writeBoundary"] ''
      FONT_NAME="EnvyCodeR"
      FONT_DIR="$HOME/.local/share/fonts"
      FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/EnvyCodeR.zip"

      if [ ! -d "$FONT_DIR/$FONT_NAME" ]; then
        $DRY_RUN_CMD mkdir -p "$FONT_DIR/$FONT_NAME"
        $DRY_RUN_CMD ${pkgs.curl}/bin/curl -L -o "/tmp/$FONT_NAME.zip" "$FONT_URL"
        $DRY_RUN_CMD ${pkgs.unzip}/bin/unzip -o "/tmp/$FONT_NAME.zip" -d "$FONT_DIR/$FONT_NAME"
        $DRY_RUN_CMD rm "/tmp/$FONT_NAME.zip"
        $DRY_RUN_CMD ${pkgs.fontconfig}/bin/fc-cache -f
        echo "Installed Nerd Font: $FONT_NAME"
      else
        echo "Nerd Font $FONT_NAME already installed"
      fi
    '';

    # Generate SSH key (ed25519) if it doesn't exist
    # Matches the behavior from the legacy ssh setup script
    generateSSHKey = config.lib.dag.entryAfter ["writeBoundary"] ''
      SSH_DIR="$HOME/.ssh"
      SSH_KEY="$SSH_DIR/id_ed25519"

      if [ ! -f "$SSH_KEY" ]; then
        $DRY_RUN_CMD mkdir -p "$SSH_DIR"
        $DRY_RUN_CMD chmod 700 "$SSH_DIR"
        $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "$USER@$(hostname)"
        echo "Generated SSH key at $SSH_KEY"
        echo ""
        echo "Your public key:"
        cat "$SSH_KEY.pub"
        echo ""
        echo "To add this key to GitHub:"
        echo "  1. Copy the public key above"
        echo "  2. Go to https://github.com/settings/keys"
        echo "  3. Click 'New SSH key' and paste"
      else
        echo "SSH key already exists at $SSH_KEY"
      fi
    '';
  };
}
