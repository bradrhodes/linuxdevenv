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
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    extraConfig = ''
      # Enable mouse support
      set -g mouse on

      # Start windows and panes at 1, not 0
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # Better split commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
    '';
  };
}
