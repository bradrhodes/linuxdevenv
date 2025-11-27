{ config, pkgs, ... }:

{
  # ===== STARSHIP PROMPT =====
  programs.starship = {
    enable = true;
  };

  # Source the TOML preset so you can edit it like any other dotfile
  xdg.configFile."starship.toml".source = ../dotfiles/starship.toml;
}
