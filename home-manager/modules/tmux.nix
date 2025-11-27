{ config, pkgs, ... }:

{
  # ===== TMUX =====
  programs.tmux = {
    enable = true;
    prefix = "C-a";  # Change prefix from C-b to C-a
    terminal = "screen-256color";
    escapeTime = 0;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      sensible      # Sensible default settings
      resurrect     # Save/restore tmux sessions
      continuum     # Automatic session save/restore
      {
        plugin = resurrect;
        extraConfig = builtins.readFile ../dotfiles/tmux/resurrect.conf;
      }
      {
        plugin = continuum;
        extraConfig = builtins.readFile ../dotfiles/tmux/continuum.conf;
      }
    ];

    extraConfig = builtins.readFile ../dotfiles/tmux/tmux.conf;
  };
}
