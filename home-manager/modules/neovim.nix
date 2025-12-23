{ config, pkgs, ... }:

{
  # ===== NEOVIM =====
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim/lua/config/options.lua".source = ../dotfiles/nvim/options.lua;
}
