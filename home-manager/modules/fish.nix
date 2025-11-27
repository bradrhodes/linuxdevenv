{ config, pkgs, ... }:

{
  # ===== FISH SHELL =====
  programs.fish = {
    enable = true;

    # Fish plugins (fisher not needed - HM manages plugins directly)
    plugins = [
      # Bass: run Bash scripts/commands in Fish
      {
        name = "bass";
        src = pkgs.fetchFromGitHub {
          owner = "edc";
          repo = "bass";
          rev = "7aae6a85c24660422ea3f3f4629bb4a8d30df3ba";
          sha256 = "sha256-XpB8u2CcX7jkd+FT3AYJtGwBtmNcLXtfMyT/z7gfyQw=";
        };
      }
      # Z: directory jumper (tracks frecent directories)
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      # Autopair: auto-close brackets, quotes, etc.
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      # FZF integration
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
    ];

    # Shell initialization (runs on shell start)
    shellInit = builtins.readFile ../dotfiles/fish/shell_init.fish;

    # Interactive shell initialization (only runs in interactive shells)
    interactiveShellInit = builtins.readFile ../dotfiles/fish/interactive_init.fish;

    # Custom functions
    functions = {
      # Docker compose shortcuts
      dcu = "docker compose up -d";
      dcd = "docker compose down";

      # Tmux attach
      tma = "tmux a -t $argv[1]";

      # Emacs client wrapper
      emacs = "emacsclient -c -a 'emacs'";
    };

    # Shell aliases
    shellAliases = {
      # Modern CLI replacements
      ls = "eza";
      ll = "eza -la -g --icons";
      cat = "bat";
      grep = "rg";

      # Neovim shortcuts
      vi = "nvim";
      vim = "nvim";
    };
  };

}
