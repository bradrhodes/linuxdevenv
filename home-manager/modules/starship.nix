{ config, pkgs, ... }:

{
  # ===== STARSHIP PROMPT =====
  programs.starship = {
    enable = true;

    settings = {
      # Use pastel-powerline preset (from your public.yml)
      format = "$all";

      # Add some sensible defaults
      command_timeout = 1000;

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # You can customize further or load a preset
      # starship preset pastel-powerline -o ~/.config/starship.toml
    };
  };
}
