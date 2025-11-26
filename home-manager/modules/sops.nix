{ config, pkgs, ... }:

{
  # ===== SOPS SECRETS MANAGEMENT =====
  # Integration with your existing SOPS/Age setup
  sops = {
    # Path to your Age key (same as used by manage-secrets.sh)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Path to your encrypted secrets file
    defaultSopsFile = ../bash/config/private.yml;

    # Define which secrets to extract
    secrets = {
      "git_user/name" = {};
      "git_user/email" = {};
      "git_user/signing_key" = {};
    };
  };
}
