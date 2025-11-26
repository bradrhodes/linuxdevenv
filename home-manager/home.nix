{ config, pkgs, ... }:

{
  # Import all module files
  imports = [
    ./modules/sops.nix
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/fish.nix
    ./modules/tmux.nix
    ./modules/neovim.nix
    ./modules/starship.nix
    ./modules/activation.nix
  ];

  # ===== HOME MANAGER CONFIGURATION =====
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "bigb";
  home.homeDirectory = "/home/bigb";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
