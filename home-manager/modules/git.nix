{ config, pkgs, ... }:

{
  # ===== GIT =====
  programs.git = {
    enable = true;

    # Git user configuration loaded from encrypted private.yml via SOPS
    userName = builtins.readFile config.sops.secrets."git_user/name".path;
    userEmail = builtins.readFile config.sops.secrets."git_user/email".path;

    # Uncomment to enable GPG commit signing (if you have a signing key)
    # signing = {
    #   key = builtins.readFile config.sops.secrets."git_user/signing_key".path;
    #   signByDefault = true;
    # };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      color.ui = true;
    };

    # Git aliases - merged from your existing config + some useful additions
    aliases = {
      # Your existing aliases
      logg = "log --abbrev-commit --decorate --oneline --graph";
      la = "log --abbrev-commit --decorate --oneline --graph --all";
      ss = "status -s";
      open = "!start `git remote get-url origin`";
      browse = "!git open";
      aa = "add --all";
      cm = "commit -m";
      ignore = "!gi() { curl -sL https://www.gitignore.io/api/$@ ;}; gi";

      # Additional useful aliases
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };
}
