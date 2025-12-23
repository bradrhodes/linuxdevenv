{ config, pkgs, ... }:

{
  # ===== PACKAGES =====
  # All packages from your public.yml consolidated here
  home.packages = with pkgs; [
    # Core CLI tools (from nix_packages)
    fish
    fzf
    nushell
    ncdu
    duckdb
    mc              # Midnight Commander
    # neovim - managed via programs.neovim instead
    ripgrep
    bat
    htop
    eza
    fontconfig
    unzip
    gcc
    glow

    # Command correction tool (was pay-respects in your config)
    pay-respects

    # From brew_packages - now all in nixpkgs
    uv              # Python package manager
    lazygit         # Git TUI

    # From apt_packages (build-essential equivalents)
    gnumake
    binutils

    # Python tools
    posting         # HTTP client TUI

    # Additional useful tools
    chezmoi         # Will eventually replace this with HM dotfile management

    # Secrets management (from bootstrap.sh requirements)
    sops            # Mozilla SOPS for secrets encryption
    age             # Modern encryption tool
    yq-go           # YAML processor (Go version, not Python)

    # SSH and Git tools
    openssh         # SSH client and keygen
    git             # Version control
  ];

  # ===== ENVIRONMENT VARIABLES =====
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
