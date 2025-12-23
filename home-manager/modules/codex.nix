{ config, pkgs, lib, ... }:

{
  # ===== OPENAI CODEX CLI =====
  # Coding agent from OpenAI that runs in your terminal

  # Ensure Node.js is available for npm packages
  home.packages = with pkgs; [
    nodejs_22  # Latest LTS version
  ];

  # Configure npm to use a user-writable directory for global packages
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };

  # Add npm global bin to PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
  ];

  # Install Codex CLI via npm global package
  # This activation script ensures the package is installed
  home.activation.installCodexCLI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    NPM_PREFIX="$HOME/.npm-global"
    export NPM_CONFIG_PREFIX="$NPM_PREFIX"

    if [ ! -d "$NPM_PREFIX" ]; then
      echo "Creating npm global directory at $NPM_PREFIX"
      $DRY_RUN_CMD mkdir -p "$NPM_PREFIX"
    fi

    if ! command -v codex &> /dev/null || [ ! -f "$NPM_PREFIX/bin/codex" ]; then
      echo "Installing OpenAI Codex CLI to $NPM_PREFIX..."
      $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install -g @openai/codex
    else
      INSTALLED_VERSION=$(${pkgs.nodejs_22}/bin/npm list -g @openai/codex --depth=0 2>/dev/null | grep @openai/codex || echo "")
      if [ -z "$INSTALLED_VERSION" ]; then
        echo "Codex command found but npm package not detected. Installing @openai/codex..."
        $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install -g @openai/codex
      else
        echo "OpenAI Codex CLI already installed: $INSTALLED_VERSION"
      fi
    fi
  '';
}
