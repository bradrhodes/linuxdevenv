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
  xdg.configFile."nvim/lua/plugins/snacks.lua".source = ../dotfiles/nvim/plugins/snacks.lua;
}
