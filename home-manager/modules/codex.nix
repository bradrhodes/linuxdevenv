{ config, pkgs, lib, ... }:

{
  # ===== OPENAI CODEX CLI =====
  # Coding agent from OpenAI that runs in your terminal

  # Ensure Node.js is available for npm packages
  home.packages = with pkgs; [
    nodejs_22  # Latest LTS version
  ];

  # Install Codex CLI via npm global package
  # This activation script ensures the package is installed
  home.activation.installCodexCLI = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ! command -v codex &> /dev/null; then
      echo "Installing OpenAI Codex CLI..."
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
