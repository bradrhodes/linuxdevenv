{ config, pkgs, ... }:

{
  # ===== GIT =====
  programs.git = {
    enable = true;
  };

  # Manage ~/.gitconfig as a normal dotfile
  home.file.".gitconfig".source = ../dotfiles/git/gitconfig;

  # Set git user config from SOPS secrets
  # This runs after secrets are decrypted
  home.activation.writeGitUserConfig = config.lib.dag.entryAfter ["linkGeneration"] ''
    if [ -f "${config.sops.secrets."git_user/name".path}" ] && [ -f "${config.sops.secrets."git_user/email".path}" ]; then
      GIT_NAME=$(cat "${config.sops.secrets."git_user/name".path}")
      GIT_EMAIL=$(cat "${config.sops.secrets."git_user/email".path}")
      GIT_USER_FILE="$HOME/.gitconfig.local"
      $DRY_RUN_CMD cat <<EOF > "$GIT_USER_FILE"
[user]
        name = $GIT_NAME
        email = $GIT_EMAIL
EOF
      echo "Git user config set from SOPS secrets at $GIT_USER_FILE"
    else
      echo "Warning: Git user secrets not found, skipping git config setup"
    fi
  '';
}
