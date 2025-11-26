{ config, pkgs, ... }:

{
  # ===== NEOVIM =====
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
