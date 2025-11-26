{ config, pkgs, ... }:

{
  # ===== GIT =====
  programs.git = {
    enable = true;

    # NOTE: Git user config is set via activation script below using SOPS secrets
    # This is because sops-nix decrypts secrets at activation time, not evaluation time

    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
      color.ui = true;

      alias = {
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
  };

  # Set git user config from SOPS secrets
  # This runs after secrets are decrypted
  home.activation.setGitConfig = config.lib.dag.entryAfter ["writeBoundary"] ''
    if [ -f "${config.sops.secrets."git_user/name".path}" ] && [ -f "${config.sops.secrets."git_user/email".path}" ]; then
      GIT_NAME=$(cat "${config.sops.secrets."git_user/name".path}")
      GIT_EMAIL=$(cat "${config.sops.secrets."git_user/email".path}")
      $DRY_RUN_CMD ${pkgs.git}/bin/git config --global user.name "$GIT_NAME"
      $DRY_RUN_CMD ${pkgs.git}/bin/git config --global user.email "$GIT_EMAIL"
      echo "Git user config set from SOPS secrets"
    else
      echo "Warning: Git user secrets not found, skipping git config setup"
    fi
  '';
}
