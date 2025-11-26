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
    shellInit = ''
      # Add ~/.local/bin to PATH if it exists and is not already present
      if test -d ~/.local/bin
        if not contains ~/.local/bin $PATH
          set -x PATH ~/.local/bin $PATH
        end
      end

      # Add .NET to PATH if not already present
      if not contains $DOTNET_ROOT $PATH
        set -x PATH $PATH $HOME/.dotnet
      end

      # Source Nix daemon Fish profile if it exists
      if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end

      # Source /etc/profile via bass
      bass source /etc/profile

      # Initialize Homebrew if available
      if test -d /home/linuxbrew/.linuxbrew
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
      end

      # FZF Fish integration
      fzf --fish | source
    '';

    # Interactive shell initialization (only runs in interactive shells)
    interactiveShellInit = ''
      # Initialize Starship prompt
      starship init fish | source

      # Initialize pay-respects if available
      if type -q pay-respects
        pay-respects --init fish | source
      end

      # Start Emacs daemon if available and not running
      if test -f /usr/bin/emacs
        if not pgrep -x emacs > /dev/null
          /usr/bin/emacs --daemon
        end
      end
    '';

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
